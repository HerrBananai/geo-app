import 'package:flutter/material.dart';

/// Duolingo-inspirierte Farben, Level und Buttons.
/// Hell + Dunkel (dunkel angelehnt an Duos Nachtmodus).
class DuoColors {
  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF58A700);
  static const blue = Color(0xFF1CB0F6);
  static const blueDark = Color(0xFF1899D6);
  static const red = Color(0xFFFF4B4B);
  static const redDark = Color(0xFFD33131);
  static const yellow = Color(0xFFFFC800);
  static const yellowDark = Color(0xFFE0A800);
  static const ink = Color(0xFF3C3C3C);
  static const grey = Color(0xFF777777);
  static const edge = Color(0xFFE5E5E5);

  static const nightBg = Color(0xFF131F24);
  static const nightCard = Color(0xFF202F36);
  static const nightEdge = Color(0xFF37464F);
  static const nightText = Color(0xFFF1F7FB);

  static const levelTitles = [
    'Entdecker',
    'Pfadfinder',
    'Forscher',
    'Kartograf',
    'Globetrotter',
    'Geo-Profi',
    'Legende',
  ];

  static int levelFor(int xp) => xp ~/ 100 + 1;

  static String titleFor(int xp) =>
      levelTitles[(levelFor(xp) - 1).clamp(0, levelTitles.length - 1)];

  static double progressFor(int xp) => (xp % 100) / 100;
}

/// Dicker 3D-Button im Duolingo-Stil: fette Schrift, Unterkante als Schatten,
/// beim Drücken federt er ein.
class DuoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadow;
  final Color labelColor;
  final IconData? icon;

  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = DuoColors.green,
    this.shadow = DuoColors.greenDark,
    this.labelColor = Colors.white,
    this.icon,
  });

  /// Weiße Variante (z. B. „Nochmal").
  const DuoButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  })  : color = Colors.white,
        shadow = DuoColors.edge,
        labelColor = DuoColors.grey;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final face = disabled ? Colors.grey.shade300 : widget.color;
    final edge = disabled ? Colors.grey.shade400 : widget.shadow;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: edge, width: 2),
          boxShadow: [BoxShadow(color: edge, offset: Offset(0, _down ? 0 : 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.labelColor, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.labelColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kleine Statistik-Pille für die AppBar (Streak / XP).
class DuoStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const DuoStat({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
