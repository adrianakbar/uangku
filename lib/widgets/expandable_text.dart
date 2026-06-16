import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;

  const ExpandableText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.length <= 25) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Gunakan TextPainter untuk mendeteksi apakah teks melebihi maxLines
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        )..layout(maxWidth: constraints.maxWidth > 0 ? constraints.maxWidth : 300);

        final isLongText = textPainter.didExceedMaxLines;

        if (!isLongText) {
          return Text(
            widget.text,
            style: widget.style,
          );
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: _isExpanded ? null : widget.maxLines,
                  overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isExpanded ? LucideIcons.chevron_up : LucideIcons.chevron_down,
                size: 16,
                color: widget.style.color?.withValues(alpha: 0.5) ?? Colors.white30,
              ),
            ],
          ),
        );
      },
    );
  }
}
