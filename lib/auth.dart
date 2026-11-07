import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _ink = Color(0xFF090B12);
const _gold = Color(0xFFFFC857);
const _muted = Color(0xFF9BA3B4);

class SupabaseSetupPage extends StatelessWidget {
  const SupabaseSetupPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: _ink,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, color: _gold, size: 64),
                  SizedBox(height: 16),
                  Text('أكمل إعداد Supabase',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(
                    'شغّل التطبيق باستخدام SUPABASE_URL وSUPABASE_ANON_KEY كما هو موضح في README. لا تضع service_role key في التطبيق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class AuthGate extends StatelessWidget {
  final Widget authenticatedHome;
  const AuthGate({super.key, required this.authenticatedHome});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? client.auth.currentSession;
        return session == null ? const AuthPage() : authenticatedHome;
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_isSignUp) {
        final result = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {
            'username': _username.text.trim(),
            'display_name': _displayName.text.trim(),
          },
        );
        if (result.session == null && mounted) {
          setState(() => _notice =
              'تم إنشاء الحساب. تحقّق من بريدك الإلكتروني لتأكيده ثم سجّل الدخول.');
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر إكمال العملية. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _ink,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.play_circle_fill,
                          size: 72, color: _gold),
                      const SizedBox(height: 12),
                      const Text('ZUNO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _gold,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3)),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp
                            ? 'أنشئ حسابك وابدأ المشاركة'
                            : 'سجّل الدخول للمتابعة',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 16),
                      ),
                      const SizedBox(height: 28),
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _displayName,
                          decoration:
                              const InputDecoration(labelText: 'الاسم الظاهر'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'أدخل الاسم الظاهر'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _username,
                          decoration:
                              const InputDecoration(labelText: 'اسم المستخدم'),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.length < 3) {
                              return 'استخدم 3 أحرف على الأقل';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                              return 'استخدم أحرفًا إنجليزية أو أرقامًا أو _ فقط';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني'),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'أدخل بريدًا إلكترونيًا صحيحًا'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'كلمة المرور'),
                        validator: (v) => (v == null || v.length < 8)
                            ? 'يجب أن تكون كلمة المرور 8 أحرف على الأقل'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(color: Colors.redAccent)),
                      ],
                      if (_notice != null) ...[
                        const SizedBox(height: 12),
                        Text(_notice!, style: const TextStyle(color: _gold)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _ink,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignUp ? 'إنشاء حساب' : 'تسجيل الدخول'),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _error = null;
                                  _notice = null;
                                }),
                        child: Text(_isSignUp
                            ? 'لديك حساب؟ سجّل الدخول'
                            : 'ليس لديك حساب؟ أنشئ حسابًا'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
