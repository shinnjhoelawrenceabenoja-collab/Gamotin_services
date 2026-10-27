import 'package:flutter/material.dart';
import 'api.dart';
import 'dashboard_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController();
  final _email = TextEditingController(), _pw = TextEditingController();
  bool _register = false, _busy = false, _hide = true;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_register) {
        await Api.register(_name.text.trim(), _phone.text.trim(), _email.text.trim(), _pw.text);
      } else {
        await Api.login(_phone.text.trim(), _pw.text);
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _form,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.print_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('Gamotin Services', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(_register ? 'Create your account' : 'Sign in to continue'),
                    const SizedBox(height: 20),
                    if (_register) ...[
                      TextFormField(controller: _name, validator: _req,
                          decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(controller: _phone, validator: _req, keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    if (_register) ...[
                      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(controller: _pw, obscureText: _hide,
                        validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                        decoration: InputDecoration(labelText: 'Password', border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _hide = !_hide)))),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, height: 48,
                        child: FilledButton(onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_register ? 'Register' : 'Login'))),
                    TextButton(onPressed: () => setState(() => _register = !_register),
                        child: Text(_register ? 'I already have an account' : 'Create an account')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
