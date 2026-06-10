import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';

/// Income (solid, filled) vs expense (dashed) area/line chart.
class TFAreaChart extends StatelessWidget {
  const TFAreaChart({
    required this.income,
    required this.expense,
    this.height = 130,
    super.key,
  });

  final List<double> income;
  final List<double> expense;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _AreaPainter(
          income: income,
          expense: expense,
          pos: c.pos,
          neg: c.neg,
        ),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({
    required this.income,
    required this.expense,
    required this.pos,
    required this.neg,
  });

  final List<double> income;
  final List<double> expense;
  final Color pos;
  final Color neg;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    const bottomPad = 14.0;
    const topPad = 16.0;
    final maxV = [...income, ...expense].reduce(math.max) * 1.12;
    final n = income.length;
    double x(int i) => pad + i * (size.width - pad * 2) / (n - 1);
    double y(double v) =>
        size.height -
        bottomPad -
        (v / maxV) * (size.height - topPad - bottomPad);

    Path linePath(List<double> arr) {
      final p = Path()..moveTo(x(0), y(arr[0]));
      for (var i = 1; i < arr.length; i++) {
        p.lineTo(x(i), y(arr[i]));
      }
      return p;
    }

    // Income area fill (gradient to transparent).
    final area = linePath(income)
      ..lineTo(x(n - 1), size.height - bottomPad)
      ..lineTo(x(0), size.height - bottomPad)
      ..close();
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [pos.withValues(alpha: 0.28), pos.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(area, fill);

    // Expense dashed line.
    _drawDashed(
      canvas,
      linePath(expense),
      Paint()
        ..color = neg.withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Income solid line, then the end dot.
    canvas
      ..drawPath(
        linePath(income),
        Paint()
          ..color = pos
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(
        Offset(x(n - 1), y(income[n - 1])),
        3.4,
        Paint()..color = pos,
      );
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, dist + dash),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.income != income || old.expense != expense || old.pos != pos;
}

/// Grouped income/expense bars with month labels beneath.
class TFBarPairs extends StatelessWidget {
  const TFBarPairs({
    required this.income,
    required this.expense,
    required this.labels,
    this.height = 150,
    super.key,
  });

  final List<double> income;
  final List<double> expense;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final maxV = [...income, ...expense].reduce(math.max) * 1.1;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: height - 22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar(income[i] / maxV, c.pos),
                        const SizedBox(width: 4),
                        _bar(expense[i] / maxV, c.neg.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[i],
                    style: TFText.sans(
                      size: 10.5,
                      color: c.textDim,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(double frac, Color color) {
    return FractionallySizedBox(
      heightFactor: frac.clamp(0.0, 1.0),
      child: Container(
        width: 9,
        constraints: const BoxConstraints(minHeight: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// One slice of a [TFDonut].
class DonutSegment {
  const DonutSegment(this.value, this.color);
  final double value;
  final Color color;
}

/// A donut/ring chart with an optional centred widget.
class TFDonut extends StatelessWidget {
  const TFDonut({
    required this.segments,
    this.size = 132,
    this.stroke = 16,
    this.center,
    super.key,
  });

  final List<DonutSegment> segments;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              segments: segments,
              stroke: stroke,
              track: c.surface3,
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.stroke,
    required this.track,
  });

  final List<DonutSegment> segments;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = segments.fold<double>(0, (s, x) => s + x.value);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments || old.stroke != stroke;
}

/// A compact, axis-less sparkline.
class TFSpark extends StatelessWidget {
  const TFSpark({
    required this.data,
    required this.color,
    this.width = 90,
    this.height = 34,
    super.key,
  });

  final List<double> data;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparkPainter(data: data, color: color),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = data.reduce(math.max);
    final minV = data.reduce(math.min);
    final span = (maxV - minV) == 0 ? 1 : (maxV - minV);
    double x(int i) => i * size.width / (data.length - 1);
    double y(double v) =>
        size.height - 3 - ((v - minV) / span) * (size.height - 6);
    final path = Path()..moveTo(x(0), y(data[0]));
    for (var i = 1; i < data.length; i++) {
      path.lineTo(x(i), y(data[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.data != data || old.color != color;
}

/// A hatched placeholder block for receipt thumbnails.
class TFPlaceholder extends StatelessWidget {
  const TFPlaceholder({
    required this.label,
    this.height,
    this.width,
    super.key,
  });

  final String label;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: _HatchPainter(a: c.surface2, b: c.surface3, line: c.line),
        child: Container(
          height: height,
          // Fill the available width when no explicit width is given (e.g. a
          // grid cell), instead of shrinking to the label.
          width: width ?? double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TFText.mono(size: 9.5, color: c.textDim, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.a, required this.b, required this.line});

  final Color a;
  final Color b;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final stripe = Paint()
      ..color = b
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (var d = -size.height; d < size.width + size.height; d += 18) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        stripe,
      );
    }
    canvas
      ..restore()
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke,
      );
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.a != a || old.b != b;
}
