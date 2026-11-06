# ZUNO — short video social app starter

Arabic-first Flutter starter for a short-video social platform. This is a runnable UI prototype, not a production social network yet.

## Run
1. Install Flutter SDK.
2. `flutter create .` (inside this folder; keep `lib/main.dart`).
3. `flutter pub get`
4. `flutter run`

## Next production steps
- Configure Supabase URL + anon key in `lib/main.dart` and initialize `supabase_flutter`.
- Implement secure Storage/RLS, moderation, reporting, feed pagination, upload transcoding, and notifications.
- Add a video delivery provider (Mux/Cloudflare Stream), live streaming provider, payment/KYC provider, and legal/privacy review.
- Never put service-role keys or provider secrets in the mobile app.

## Supabase ZUNO
Project URL: `https://qklmgrwuggkdhyrwzlxj.supabase.co`
Run with: `flutter run --dart-define=SUPABASE_URL=https://qklmgrwuggkdhyrwzlxj.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY`
