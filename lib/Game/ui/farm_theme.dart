import 'package:flutter/material.dart';

/// ─────────────────────────────────────────
///  FarmTheme — Shared Design Tokens
///  Used by every screen in lib/Game/ui/
/// ─────────────────────────────────────────
abstract class FarmTheme {
  // ── Brand palette ──
  static const Color bg          = Color(0xFF0B1A12); // Deep forest black-green
  static const Color surface     = Color(0xFF132218); // Card surface
  static const Color surfaceAlt  = Color(0xFF1A2E20); // Slightly lighter card
  static const Color border      = Color(0xFF2A4030); // Subtle border
  static const Color accent      = Color(0xFF4ADE80); // Bright green accent
  static const Color accentWarm  = Color(0xFFFBBF24); // Amber / warm
  static const Color accentRed   = Color(0xFFEF4444); // Risk red
  static const Color accentBlue  = Color(0xFF60A5FA); // Info blue / rain
  static const Color textPrimary = Color(0xFFE2E8F0); // Near-white
  static const Color textMuted   = Color(0xFF6B8F71); // Muted sage

  // ── Gradients ──
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1A12), Color(0xFF0F2318), Color(0xFF091510)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2E20), Color(0xFF132218)],
  );

  static LinearGradient accentGradient = LinearGradient(
    colors: [accent.withOpacity(0.25), accent.withOpacity(0.05)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Radii ──
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  // ── Text Styles ──
  static const TextStyle headingLg = TextStyle(
    color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.3,
  );
  static const TextStyle headingMd = TextStyle(
    color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold,
  );
  static const TextStyle label = TextStyle(
    color: textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2,
  );
  static const TextStyle body = TextStyle(
    color: textPrimary, fontSize: 13, height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    color: textMuted, fontSize: 11,
  );

  // ── Box Decorations ──
  static BoxDecoration get card => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: border, width: 1),
  );

  static BoxDecoration get cardHighlight => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
    boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 12, spreadRadius: 1)],
  );

  static BoxDecoration get pill => BoxDecoration(
    color: accent.withOpacity(0.08),
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: accent.withOpacity(0.2)),
  );

  // ── Shared AppBar ──
  static AppBar appBar(BuildContext context, String title, {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: const Color(0xFF0B1A12),
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      title: Text(title, style: headingMd),
      iconTheme: const IconThemeData(color: accent),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: border),
      ),
    );
  }

  // ── Stat chip ──
  static Widget statChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        ]),
      ]),
    );
  }

  // ── Section header ──
  static Widget sectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: label),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── Primary Button ──
  static Widget primaryButton({required String text, required VoidCallback onPressed, IconData? icon, bool fullWidth = true}) {
    final btn = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: const Color(0xFF0B1A12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        elevation: 0,
        minimumSize: fullWidth ? const Size(double.infinity, 52) : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
      ]),
    );
    return btn;
  }

  // ── Ghost Button ──
  static Widget ghostButton({required String text, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textMuted,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}
