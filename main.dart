import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl =
      'https://qklmgrwuggkdhyrwzlxj.supabase.co';

  const supabaseKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  if (supabaseKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  runApp(const ZunoApp());
}

const ink = Color(0xFF090B12);
const panel = Color(0xFF151925);
const gold = Color(0xFFFFC857);
const muted = Color(0xFF9BA3B4);

class ZunoApp extends StatelessWidget {
  const ZunoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZUNO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          surface: panel,
        ),
      ),
      home: Supabase.instance.isInitialized
          ? const AuthGate()
          : const SetupPage(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user =
            Supabase.instance.client.auth.currentUser;

        if (user == null) {
          return const AuthPage();
        }

        return const HomePage();
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isSignup = false;
  bool loading = false;

  String message = '';

  Future<void> submit() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final auth = Supabase.instance.client.auth;

      if (isSignup) {
        await auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        message =
            'تم إنشاء الحساب. راجع بريدك الإلكتروني إذا طُلب التأكيد.';
      } else {
        await auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on AuthException catch (e) {
      message = e.message;
    } catch (e) {
      message = 'حدث خطأ أثناء الاتصال.';
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ZUNO',
                style: TextStyle(
                  color: gold,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                isSignup
                    ? 'إنشاء حساب جديد'
                    : 'تسجيل الدخول',
                style: const TextStyle(fontSize: 24),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  filled: true,
                  fillColor: panel,
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  filled: true,
                  fillColor: panel,
                ),
              ),

              const SizedBox(height: 20),

              if (message.isNotEmpty)
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: gold),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : submit,
                  child: Text(
                    loading
                        ? 'جاري التنفيذ...'
                        : isSignup
                            ? 'إنشاء الحساب'
                            : 'دخول',
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    isSignup = !isSignup;
                    message = '';
                  });
                },
                child: Text(
                  isSignup
                      ? 'لديك حساب؟ سجل الدخول'
                      : 'ليس لديك حساب؟ أنشئ حسابًا',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'يجب تشغيل التطبيق باستخدام '
            'SUPABASE_ANON_KEY.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ZUNO',
          style: TextStyle(color: gold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'أهلًا بك في ZUNO 🎉',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
