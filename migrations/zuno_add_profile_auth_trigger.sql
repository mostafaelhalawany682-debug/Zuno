-- Additive ZUNO Auth/profile migration for the existing schema.
-- Preserves existing profile fields and RLS policies.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS display_name text NOT NULL DEFAULT '';

-- Preserve existing full_name values when that legacy column exists.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'full_name'
  ) THEN
    EXECUTE $sql$
      UPDATE public.profiles
      SET display_name = COALESCE(NULLIF(display_name, ''), full_name, '')
      WHERE display_name = ''
    $sql$;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  base_username text;
  generated_username text;
  new_display_name text;
BEGIN
  base_username := lower(regexp_replace(
    coalesce(new.raw_user_meta_data ->> 'username', 'zuno'),
    '[^a-zA-Z0-9_]', '', 'g'
  ));
  IF length(base_username) < 3 THEN
    base_username := 'zuno';
  END IF;

  generated_username := left(base_username, 20) || '_' ||
    right(replace(new.id::text, '-', ''), 8);
  new_display_name := coalesce(
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'full_name',
    ''
  );

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'full_name'
  ) THEN
    EXECUTE 'INSERT INTO public.profiles (id, username, display_name, full_name) '
      || 'VALUES ($1, $2, $3, $3) ON CONFLICT (id) DO NOTHING'
      USING new.id, generated_username, new_display_name;
  ELSE
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (new.id, generated_username, new_display_name)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();
