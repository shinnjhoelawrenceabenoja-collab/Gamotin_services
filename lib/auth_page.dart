import 'package:flutter/material.dart';
import 'api.dart';
import 'dashboard_page.dart';
import 'theme.dart';

/// Login + Register in one page (toggle).
class AuthPage extends StatefulWidget {
  final bool register;
  const AuthPage({super.key, this.register = false});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool _reg = widget.register;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false, _hide = true;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim().toLowerCase();
      if (_reg) {
        await Api.register(_name.text.trim(), _phone.text.trim(), email, _pass.text);
      } else {
        await Api.login(email, _pass.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          G.fade(const DashboardPage()), (_) => false);
    } on ApiException catch (e) {
      if (mounted) G.snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _req(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 8, 24, 30),
          decoration: const BoxDecoration(
            gradient: G.gradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_reg ? 'Create account' : 'Welcome back',
                style: const TextStyle(
                    color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                _reg
                    ? 'We need your contact so we can reach you when your print is done.'
                    : 'Login to send your print orders.',
                style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(children: [
                if (_reg) ...[
                  TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => _req(v, 'Name')),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Contact number',
                          prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) => (v == null || v.trim().length < 7)
                          ? 'Enter a valid contact number'
                          : null),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null),
                const SizedBox(height: 14),
                TextFormField(
                    controller: _pass,
                    obscureText: _hide,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _hide = !_hide)),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(_reg ? 'Register' : 'Login',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _reg = !_reg),
                  child: Text(_reg
                      ? 'Already have an account? Login'
                      : "No account yet? Register"),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
