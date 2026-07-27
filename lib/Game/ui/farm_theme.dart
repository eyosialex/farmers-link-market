import 'package:flutter/material.dart';

/// ─────────────────────────────────────────
///  FarmTheme — Shared Design Tokens
///  Used by every screen in lib/Game/ui/
/// ─────────────────────────────────────────
abstract class FarmTheme {
  // ── Brand palette ──
  static const Color bg          = Color(0xFFF5F6FA); // App light background
  static const Color surface     = Colors.white;      // Card surface
  static const Color surfaceAlt  = Color(0xFFF5F6FA); // Slightly darker card/bg
  static const Color border      = Color(0xFFE0E0E0); // Subtle border
  static const Color accent      = Color(0xFF2E7D32); // App primary green
  static const Color accentWarm  = Colors.orange;     // Amber / warm
  static const Color accentRed   = Colors.red;        // Risk red
  static const Color accentBlue  = Colors.blue;       // Info blue / rain
  static const Color textPrimary = Colors.black87;    // Dark text
  static const Color textMuted   = Colors.grey;       // Muted text

  // ── Gradients ──
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F6FA), Color(0xFFF5F6FA)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Colors.white],
  );

  static LinearGradient accentGradient = LinearGradient(
    colors: [accent.withOpacity(0.15), accent.withOpacity(0.02)],
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
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, spreadRadius: 1)],
  );

  static BoxDecoration get pill => BoxDecoration(
    color: accent.withOpacity(0.08),
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: accent.withOpacity(0.2)),
  );

  // ── Shared AppBar ──
  static AppBar appBar(BuildContext context, String title, {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: Colors.white,
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
        foregroundColor: Colors.white,
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
