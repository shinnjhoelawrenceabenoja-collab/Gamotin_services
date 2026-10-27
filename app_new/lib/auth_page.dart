import 'package:flutter/material.dart';
import 'api.dart';
import 'dashboard_page.dart';
import 'theme.dart';
import 'widgets.dart';

class AuthPage extends StatefulWidget {
  final bool register;
  const AuthPage({super.key, this.register = false});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController();
  final _email = TextEditingController(), _pw = TextEditingController();
  late bool _register = widget.register;
  bool _busy = false, _hide = true;

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
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardPage()), (_) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            Container(
              width: double.infinity, height: 320,
              decoration: const BoxDecoration(color: purple, borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(260, 140))),
              child: SafeArea(
                child: Stack(children: [
                  if (Navigator.canPop(context))
                    IconButton(color: Colors.white, icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.print_outlined, size: 58, color: Colors.white),
                      const SizedBox(height: 8),
                      const Text('GAMOTIN', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(_register ? 'Create your account' : 'Sign in to continue', style: const TextStyle(color: soft, fontSize: 14)),
                    ]),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 30, 40, 30),
              child: Form(
                key: _form,
                child: Column(children: [
                  if (_register) ...[
                    PillField(controller: _name, hint: 'Full name', validator: _req),
                    const SizedBox(height: 14),
                  ],
                  PillField(controller: _phone, hint: 'Phone number', type: TextInputType.phone, validator: _req),
                  const SizedBox(height: 14),
                  if (_register) ...[
                    PillField(controller: _email, hint: 'Email (optional)', type: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                  ],
                  PillField(
                    controller: _pw, hint: 'Password', obscure: _hide,
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                    suffix: IconButton(
                        icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: purple),
                        onPressed: () => setState(() => _hide = !_hide)),
                  ),
                  const SizedBox(height: 26),
                  BigButton(_register ? 'Register' : 'Login', onPressed: _submit, loading: _busy),
                  TextButton(
                    onPressed: () => setState(() => _register = !_register),
                    child: Text(_register ? 'I already have an account' : 'Create an account',
                        style: const TextStyle(color: grey, fontSize: 13)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}
