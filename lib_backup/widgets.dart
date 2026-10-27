import 'package:flutter/material.dart';
import 'theme.dart';

/// Outlined capsule text field (purple outline on white, white outline on purple).
class PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure, onPurple;
  final int lines;
  final TextInputType? type;
  final String? Function(String?)? validator;
  final Widget? suffix;
  const PillField({super.key, required this.controller, required this.hint, this.obscure = false,
      this.onPurple = false, this.lines = 1, this.type, this.validator, this.suffix});

  @override
  Widget build(BuildContext context) {
    final c = onPurple ? Colors.white : purple;
    OutlineInputBorder b(Color col, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(lines > 1 ? 24 : 30), borderSide: BorderSide(color: col, width: w));
    return TextFormField(
      controller: controller, obscureText: obscure, keyboardType: type, validator: validator,
      minLines: lines, maxLines: lines, cursorColor: c,
      style: TextStyle(color: onPurple ? Colors.white : purpleDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, suffixIcon: suffix,
        hintStyle: TextStyle(color: onPurple ? soft : purple.withOpacity(.8), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        enabledBorder: b(c, 2), focusedBorder: b(c, 3), errorBorder: b(pink, 2), focusedErrorBorder: b(pink, 3),
      ),
    );
  }
}

/// Selectable pill (white when selected, dark purple otherwise) for use on purple screens.
class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const Pill(this.label, {super.key, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: selected ? Colors.white : purpleDark,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? purpleDark : Colors.white)),
          ),
        ),
      );
}

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined, loading;
  final Color color, textColor;
  const BigButton(this.label, {super.key, required this.onPressed, this.outlined = false, this.loading = false,
      this.color = purple, this.textColor = Colors.white});
  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: outlined ? purple : textColor))
        : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
    final shape = const StadiumBorder();
    return SizedBox(
      width: double.infinity, height: 54,
      child: outlined
          ? OutlinedButton(onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(shape: shape, foregroundColor: purpleDark, side: const BorderSide(color: purple, width: 2)),
              child: child)
          : FilledButton(onPressed: loading ? null : onPressed,
              style: FilledButton.styleFrom(shape: shape, backgroundColor: color, foregroundColor: textColor),
              child: child),
    );
  }
}

/// Decorative concentric rings used on the splash and welcome screens.
class Ring extends StatelessWidget {
  final double size;
  const Ring(this.size, {super.key});
  @override
  Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA56EE0), width: 2)));
}

class LogoCircle extends StatelessWidget {
  final double size;
  const LogoCircle(this.size, {super.key});
  @override
  Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(Icons.print_outlined, size: size * .5, color: purple));
}
