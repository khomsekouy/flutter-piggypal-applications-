import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';

/// Tone variants for [TFPill].
enum PillTone { pos, neg, warn, primary, muted }

/// A rounded surface container with hairline border (the prototype's `.card`).
class TFCard extends StatelessWidget {
  const TFCard({
    required this.child,
    this.padding,
    this.radius = 20,
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final body = Container(
      padding: padding ?? EdgeInsets.all(context.tf.cardPad),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.line),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }
}

/// A small status/label chip.
class TFPill extends StatelessWidget {
  const TFPill({
    required this.label,
    required this.tone,
    this.dot = false,
    this.leading,
    super.key,
  });

  final String label;
  final PillTone tone;
  final bool dot;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final (fg, bg) = switch (tone) {
      PillTone.pos => (c.pos, c.posSoft),
      PillTone.neg => (c.neg, c.negSoft),
      PillTone.warn => (c.warn, c.warnSoft),
      PillTone.primary => (
        Color.lerp(c.primary, Colors.white, 0.22)!,
        c.primarySoft,
      ),
      PillTone.muted => (c.textMuted, c.surface3),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: 13),
              child: leading!,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TFText.sans(
              size: 11.5,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps a domain status to the right pill tone + copy.
class TFStatusPill extends StatelessWidget {
  const TFStatusPill.program(this.status, {super.key});
  const TFStatusPill.pay(this.status, {super.key});
  const TFStatusPill.receipt(this.status, {super.key});

  final Object status;

  @override
  Widget build(BuildContext context) {
    final (PillTone tone, String label, bool dot) = switch (status) {
      ProgramStatus.active => (PillTone.pos, 'Active', true),
      ProgramStatus.upcoming => (PillTone.primary, 'Upcoming', true),
      ProgramStatus.completed => (PillTone.muted, 'Completed', false),
      PayStatus.paid => (PillTone.pos, 'Paid', true),
      PayStatus.partial => (PillTone.warn, 'Partial', true),
      PayStatus.pending => (PillTone.neg, 'Pending', true),
      ReceiptStatus.matched => (PillTone.pos, 'Matched', true),
      ReceiptStatus.unmatched => (PillTone.warn, 'Unmatched', true),
      ReceiptStatus.review => (PillTone.primary, 'In review', true),
      _ => (PillTone.muted, status.toString(), false),
    };
    return TFPill(label: label, tone: tone, dot: dot);
  }
}

/// Initials avatar, optionally hue-tinted.
class TFAvatar extends StatelessWidget {
  const TFAvatar({
    required this.name,
    this.hue = 250,
    this.size = 40,
    super.key,
  });

  final String name;
  final double hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tfCatSoft(hue),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        initials,
        style: TFText.num(
          size: size * 0.36,
          color: tfCatColor(hue),
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

/// A rounded square holding a glyph/code over a tinted background.
class TFGlyphBadge extends StatelessWidget {
  const TFGlyphBadge({
    required this.child,
    this.hue,
    this.fg,
    this.bg,
    this.size = 40,
    this.radius,
    super.key,
  });

  final Widget child;
  final double? hue;
  final Color? fg;
  final Color? bg;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final fgColor = fg ?? (hue != null ? tfCatColor(hue!) : null);
    final bgColor = bg ?? (hue != null ? tfCatSoft(hue!) : null);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius ?? size * 0.30),
      ),
      child: DefaultTextStyle.merge(
        style: TFText.num(size: size * 0.3, color: fgColor),
        child: IconTheme.merge(
          data: IconThemeData(color: fgColor, size: size * 0.5),
          child: child,
        ),
      ),
    );
  }
}

/// A thin progress bar; turns red when [over].
class TFProgress extends StatelessWidget {
  const TFProgress({
    required this.pct,
    this.color,
    this.over = false,
    super.key,
  });

  final num pct;
  final Color? color;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final v = (pct.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 7,
        color: c.surface3,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              color: over ? c.neg : (color ?? c.primary),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

/// A KPI tile: capped icon + label, big value, optional delta line.
class TFTile extends StatelessWidget {
  const TFTile({
    required this.icon,
    required this.label,
    required this.value,
    this.tone,
    this.delta,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? tone;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return TFCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tone ?? c.textMuted),
              const SizedBox(width: 7),
              Text(
                label,
                style: TFText.sans(
                  size: 12,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(value, style: TFText.num(size: 23, color: c.text)),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(
              '${delta! >= 0 ? '▲' : '▼'} ${delta!.abs()}% vs last',
              style: TFText.sans(
                size: 12,
                color: delta! >= 0 ? c.pos : c.neg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A section header with an optional trailing action link.
class TFSectionLabel extends StatelessWidget {
  const TFSectionLabel({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TFText.sans(
              size: 14,
              weight: FontWeight.w700,
              color: c.text,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: TFText.sans(
                  size: 12.5,
                  color: c.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small metric stack (value over label) used inside cards.
class TFMetric extends StatelessWidget {
  const TFMetric({
    required this.label,
    required this.value,
    this.tone,
    super.key,
  });

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TFText.num(size: 15, color: tone ?? c.text)),
        const SizedBox(height: 1),
        Text(
          label,
          style: TFText.sans(
            size: 11,
            color: c.textDim,
          ),
        ),
      ],
    );
  }
}

/// A chart legend swatch ("Income" / "Expenses").
class TFLegend extends StatelessWidget {
  const TFLegend({
    required this.color,
    required this.label,
    this.dashed = false,
    super.key,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(16, 3),
          painter: _DashLinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TFText.sans(
            size: 12,
            color: c.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DashLinePainter extends CustomPainter {
  _DashLinePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    const dash = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(0, size.width), y),
        paint,
      );
      x += dash * 2;
    }
  }

  @override
  bool shouldRepaint(_DashLinePainter old) =>
      old.color != color || old.dashed != dashed;
}

/// A label-value row used in detail/statement cards.
class TFDetailRow extends StatelessWidget {
  const TFDetailRow({
    required this.label,
    required this.value,
    this.last = false,
    super.key,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TFText.sans(
              size: 13.5,
              weight: FontWeight.w500,
              color: c.textMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TFText.sans(size: 13.5, color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}
