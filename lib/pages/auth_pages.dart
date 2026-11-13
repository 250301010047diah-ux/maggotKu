import 'package:flutter/material.dart';
import '../data/api.dart';
import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool show = false;
  bool sulky = false;
  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  bool loading = false;

  Future<void> enter() async {
    if (!form.currentState!.validate()) {
      setState(() => sulky = true);
      return;
    }
    final s = AppScope.of(context);
    setState(() => loading = true);
    try {
      await s.login(email.text.trim(), pass.text);
      if (mounted) _keBeranda();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => sulky = true);
      toast(context, e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _keBeranda() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        children: [
          // ---------- Hero ----------
          Container(
            decoration: const BoxDecoration(
              gradient: warmGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(44)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(44),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -60,
                    top: -40,
                    child: _orb(200, Colors.white.withValues(alpha: 0.06)),
                  ),
                  Positioned(
                    left: -60,
                    bottom: -80,
                    child: _orb(190, champagne.withValues(alpha: 0.12)),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, top + 16, 24, 60),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              color: champagne,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'MaggotKu',
                              style: TextStyle(
                                fontFamily: headFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Mascot(
                            mood: sulky ? MaggotMood.sulky : MaggotMood.happy,
                            size: 128,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Selamat datang kembali',
                          style: TextStyle(
                            fontFamily: headFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Masuk untuk melanjutkan budidayamu',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ---------- Form ----------
          Transform.translate(
            offset: const Offset(0, -34),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FadeSlideIn(
                child: GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: form,
                    onChanged: () {
                      if (sulky) setState(() => sulky = false);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: emailText,
                        ),
                        gap(14),
                        TextFormField(
                          controller: pass,
                          obscureText: !show,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => show = !show),
                              icon: Icon(
                                show
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                          ),
                          validator: requiredText,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                openPage(context, const ForgotPage()),
                            child: const Text('Lupa password?'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: loading ? null : enter,
                          child: loading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Masuk'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Belum punya akun?', style: TextStyle(color: muted)),
                TextButton(
                  onPressed: () => openPage(context, const RegisterPage()),
                  child: const Text('Daftar sekarang'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

/// Kerangka halaman autentikasi lain (daftar, lupa & reset password).
class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.title,
    required this.subtitle,
    required this.children,
    this.mood = MaggotMood.happy,
  });
  final String title, subtitle;
  final List<Widget> children;
  final MaggotMood mood;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: elegantAppBar(context, ''),
    body: PageBody(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        FadeSlideIn(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: headFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        height: 1.1,
                        color: ink,
                      ),
                    ),
                    gap(8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Mascot(mood: mood, size: 100),
            ],
          ),
        ),
        gap(20),
        FadeSlideIn(
          delay: 1,
          child: GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    ),
  );
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final form = GlobalKey<FormState>();
  final nama = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirmPass = TextEditingController();
  final farm = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    nama.dispose();
    email.dispose();
    pass.dispose();
    confirmPass.dispose();
    farm.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!form.currentState!.validate()) return;
    final s = AppScope.of(context);
    setState(() => loading = true);
    try {
      await s.register(
        nama.text.trim(),
        email.text.trim(),
        pass.text,
        farm.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
      toast(context, 'Akun berhasil dibuat. Selamat datang! 🎉');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
    title: 'Buat akun\nMaggotKu',
    subtitle: 'Mulai perjalanan budidayamu bersama Maggi.',
    children: [
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nama,
              decoration: const InputDecoration(
                labelText: 'Nama',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: requiredText,
            ),
            gap(14),
            TextFormField(
              controller: farm,
              decoration: const InputDecoration(
                labelText: 'Nama peternakan',
                hintText: 'mis. Maggot Jaya Farm',
                prefixIcon: Icon(Icons.agriculture_outlined),
              ),
              validator: requiredText,
            ),
            gap(14),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: emailText,
            ),
            gap(14),
            TextFormField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (v) =>
                  (v?.length ?? 0) < 6 ? 'Minimal 6 karakter' : null,
            ),
            gap(14),
            TextFormField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi password',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              validator: (v) => v != pass.text ? 'Password tidak sama' : null,
            ),
            gap(22),
            ElevatedButton(
              onPressed: loading ? null : _daftar,
              child: loading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Buat Akun'),
            ),
          ],
        ),
      ),
      gap(6),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Sudah punya akun? Masuk'),
      ),
    ],
  );
}

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});
  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
    title: 'Lupa\npassword?',
    subtitle:
        'Tenang, masukkan email akunmu. Admin akan membantu mengatur ulang password.',
    mood: MaggotMood.sulky,
    children: [
      Form(
        key: form,
        child: TextFormField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
          validator: emailText,
        ),
      ),
      gap(20),
      ElevatedButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            toast(
              context,
              'Reset lewat email belum tersedia. Hubungi admin MaggotKu '
              'untuk mengatur ulang password akun ${email.text.trim()}.',
            );
          }
        },
        child: const Text('Minta Reset Password'),
      ),
    ],
  );
}

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});
  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final form = GlobalKey<FormState>();
  final pass = TextEditingController();
  final second = TextEditingController();
  final lama = TextEditingController();
  @override
  void dispose() {
    pass.dispose();
    second.dispose();
    lama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    // Sudah login akun online → ganti password sungguhan lewat server.
    final akun = s.online && s.loggedIn;
    return _AuthShell(
      title: 'Password\nbaru',
      subtitle: akun
          ? 'Masukkan password lama, lalu password baru yang kuat.'
          : 'Buat password yang kuat dan mudah kamu ingat.',
      children: [
        Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (akun) ...[
                TextFormField(
                  controller: lama,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password lama',
                    prefixIcon: Icon(Icons.lock_clock_outlined),
                  ),
                  validator: requiredText,
                ),
                gap(14),
              ],
              TextFormField(
                controller: pass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password baru',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) =>
                    (v?.length ?? 0) < 6 ? 'Minimal 6 karakter' : null,
              ),
              gap(14),
              TextFormField(
                controller: second,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi password',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                validator: (v) => v != pass.text ? 'Password tidak sama' : null,
              ),
              gap(22),
              ElevatedButton(
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  if (akun) {
                    final ok = await kirim(
                      context,
                      () => s.changePassword(lama.text, pass.text),
                    );
                    if (!ok) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password berhasil diubah 🔐'),
                      ),
                    );
                    return;
                  }
                  final fromLogin = !s.loggedIn;
                  navigator.popUntil((r) => r.isFirst);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        fromLogin
                            ? 'Password demo berhasil diubah. Silakan masuk 🎉'
                            : 'Password demo berhasil diubah 🎉',
                      ),
                    ),
                  );
                },
                child: const Text('Simpan Password'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
