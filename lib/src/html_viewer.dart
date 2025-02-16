import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;

/// A data model representing a highlight range inside a text.
class HighlightRange {
  final int startIndex;
  final int endIndex;
  final String color;
  final String highlightedText;
  final String note;

  HighlightRange({
    required this.startIndex,
    required this.endIndex,
    required this.color,
    required this.highlightedText,
    this.note = '',
  });
}

/// Internal helper class for highlight boundaries.
class _Boundary {
  final int index;
  final bool isStart;
  final HighlightRange highlight;

  _Boundary(this.index, this.isStart, this.highlight);
}

/// A callback signature for handling link taps in <a> tags.
typedef LinkTapCallback = void Function(String url);

/// The main widget for rendering HTML content with highlight and selection features.
class HtmlViewer extends StatefulWidget {
  final String htmlContent;
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final double lineHeight;
  final Color backgroundColor;
  final TextAlign textAlign;
  final dynamic bookData;
  final String bookId;
  final int pageNumber;
  final BuildContext context;
  final List<Map<String, dynamic>>? searchHighlights;
  final List<HighlightRange> userHighlights;

  /// A custom selection control for managing selection toolbar.
  final TextSelectionControls selectionControls;

  /// A callback for handling link taps in <a>.
  final LinkTapCallback? onLinkTap;

  /// Direction of the text (RTL or LTR).
  final TextDirection textDirection;

  const HtmlViewer({
    Key? key,
    required this.htmlContent,
    required this.fontFamily,
    required this.fontSize,
    required this.textColor,
    required this.lineHeight,
    required this.backgroundColor,
    required this.textAlign,
    required this.bookData,
    required this.pageNumber,
    required this.bookId,
    required this.context,
    required this.selectionControls,
    required this.searchHighlights,
    required this.userHighlights,
    this.onLinkTap,
    this.textDirection = TextDirection.ltr,
  }) : super(key: key);

  @override
  State<HtmlViewer> createState() => _HtmlViewerState();
}

class _HtmlViewerState extends State<HtmlViewer> {
  @override
  Widget build(BuildContext context) {
    final GlobalKey selectableTextKey = GlobalKey();

    // Parse the HTML
    final document = htmlParser.parse(widget.htmlContent);

    // Base text style
    final baseStyle = TextStyle(
      color: widget.textColor,
      fontFamily: widget.fontFamily,
      fontSize: widget.fontSize,
      height: widget.lineHeight,
    );

    final body = document.body;
    List<InlineSpan> spans = [];

    // Flattened text for highlight logic
    String completeText = _flattenInlineSpans(spans);

    // Combine user highlights and search highlights
    List<HighlightRange> combinedHighlights = [];
    if (widget.userHighlights.isNotEmpty) {
      combinedHighlights.addAll(widget.userHighlights);
    }

    if (widget.searchHighlights != null && widget.searchHighlights!.isNotEmpty) {
      final keyword = widget.searchHighlights![0]['keyword'] as String;
      int startIndex = 0;
      final lowerText = completeText.toLowerCase();
      final lowerKeyword = keyword.toLowerCase();
      while (true) {
        int matchIndex = lowerText.indexOf(lowerKeyword, startIndex);
        if (matchIndex == -1) break;
        combinedHighlights.add(
          HighlightRange(
            startIndex: matchIndex,
            endIndex: matchIndex + lowerKeyword.length,
            highlightedText: completeText.substring(
              matchIndex,
              matchIndex + lowerKeyword.length,
            ),
            color: '#ffff00',
          ),
        );
        startIndex = matchIndex + lowerKeyword.length;
      }
    }

    // Now parse the HTML with highlights
    if (body != null) {
      spans = _parseNodeToSpansWithHighlights(body, baseStyle, 0, combinedHighlights);
      completeText = _flattenInlineSpans(spans);
    }

    return Container(
      color: widget.backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: widget.textDirection,
        child: Listener(
          onPointerUp: (_) {},
          child: SelectableText.rich(
            key: selectableTextKey,
            onSelectionChanged: (selection, cause) {
              if (!selection.isCollapsed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final primaryFocus = FocusManager.instance.primaryFocus;
                  if (primaryFocus != null) {
                    final editableState = primaryFocus.context?.findAncestorStateOfType<EditableTextState>();
                    editableState?.showToolbar();
                  }
                });
              }
            },
            textAlign: widget.textAlign,
            selectionControls: widget.selectionControls,
            textSpan: TextSpan(style: baseStyle, children: spans),
          ),
        ),
      ),
    );
  }

  /// Flattens InlineSpans into a plain string, for highlight indexing.
  String _flattenInlineSpans(List<InlineSpan> spans) {
    StringBuffer buffer = StringBuffer();
    for (final span in spans) {
      if (span is TextSpan) {
        buffer.write(span.text ?? '');
      }
    }
    return buffer.toString();
  }

  /// Parses a color string like #RRGGBB or #AARRGGBB into a Color.
  Color? _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final hex = colorStr.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return null;
  }

  /// Ensures the highlight boundaries are correct with the final text indexing.
  HighlightRange adjustHighlightBoundaries(HighlightRange hl, String completeText) {
    int safeEnd = hl.endIndex <= completeText.length ? hl.endIndex : completeText.length;
    String extracted = completeText.substring(hl.startIndex, safeEnd);
    if (extracted == hl.highlightedText) {
      return hl;
    }
    int searchStart = hl.startIndex - 10;
    if (searchStart < 0) searchStart = 0;
    int newStart = completeText.indexOf(hl.highlightedText, searchStart);
    if (newStart != -1) {
      int newEnd = newStart + hl.highlightedText.length;
      return HighlightRange(
        startIndex: newStart,
        endIndex: newEnd,
        color: hl.color,
        highlightedText: hl.highlightedText,
        note: hl.note,
      );
    }
    return hl;
  }

  /// Apply highlight styling (background color, underline if there's a note).
  List<InlineSpan> _applyUserHighlightsToText(String text, TextStyle style, List<HighlightRange> highlights) {
    List<InlineSpan> spans = [];
    List<_Boundary> boundaries = [];

    for (var hl in highlights) {
      HighlightRange adjustedHl = adjustHighlightBoundaries(hl, text);
      if (adjustedHl.startIndex < adjustedHl.endIndex && adjustedHl.startIndex < text.length) {
        boundaries.add(_Boundary(adjustedHl.startIndex, true, adjustedHl));
        boundaries.add(_Boundary(adjustedHl.endIndex, false, adjustedHl));
      }
    }

    boundaries.sort((a, b) {
      if (a.index != b.index) return a.index.compareTo(b.index);
      if (a.isStart == b.isStart) return 0;
      return a.isStart ? -1 : 1;
    });

    int currentIndex = 0;
    List<HighlightRange> active = [];

    for (var boundary in boundaries) {
      int boundaryIndex = boundary.index;
      if (boundaryIndex > currentIndex) {
        String segment = text.substring(currentIndex, boundaryIndex);
        TextStyle segmentStyle = style;
        if (active.isNotEmpty) {
          active.sort((a, b) => b.startIndex.compareTo(a.startIndex));
          HighlightRange effective = active.first;
          segmentStyle = style.copyWith(backgroundColor: _parseColor(effective.color));
          if (effective.note.trim().isNotEmpty) {
            segmentStyle = segmentStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: Colors.black,
              decorationThickness: 2.0,
            );
          }
          spans.add(
            TextSpan(
              text: segment,
              style: segmentStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _showSpanDialog(context, segment, effective.note);
                },
            ),
          );
        } else {
          spans.add(TextSpan(text: segment, style: style));
        }
        currentIndex = boundaryIndex;
      }
      if (boundary.isStart) {
        active.add(boundary.highlight);
      } else {
        active.remove(boundary.highlight);
      }
    }

    if (currentIndex < text.length) {
      String segment = text.substring(currentIndex);
      TextStyle segmentStyle = style;
      if (active.isNotEmpty) {
        active.sort((a, b) => b.startIndex.compareTo(a.startIndex));
        HighlightRange effective = active.first;
        segmentStyle = style.copyWith(backgroundColor: _parseColor(effective.color));
        if (effective.note.trim().isNotEmpty) {
          segmentStyle = segmentStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: Colors.black,
            decorationThickness: 2.0,
          );
        }
        spans.add(
          TextSpan(
            text: segment,
            style: segmentStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showSpanDialog(context, segment, effective.note);
              },
          ),
        );
      } else {
        spans.add(TextSpan(text: segment, style: style));
      }
    }
    return spans;
  }

  /// Recursively parse DOM nodes to InlineSpans, handling highlights as well.
  List<InlineSpan> _parseNodeToSpansWithHighlights(
    dom.Node node,
    TextStyle currentStyle,
    int offset,
    List<HighlightRange> globalHighlights,
  ) {
    List<InlineSpan> spans = [];

    if (node is dom.Text) {
      String textStr = node.text ?? '';
      int localLength = textStr.length;

      // Find highlights that intersect with this text node
      List<HighlightRange> localHighlights = [];
      for (var hl in globalHighlights) {
        if (hl.endIndex > offset && hl.startIndex < offset + localLength) {
          int localStart = hl.startIndex < offset ? 0 : hl.startIndex - offset;
          int localEnd = hl.endIndex > offset + localLength ? localLength : hl.endIndex - offset;
          localHighlights.add(
            HighlightRange(
              startIndex: localStart,
              endIndex: localEnd,
              color: hl.color,
              highlightedText: hl.highlightedText,
              note: hl.note,
            ),
          );
        }
      }

      // Apply highlights to this text segment
      spans.addAll(_applyUserHighlightsToText(textStr, currentStyle, localHighlights));
      return spans;
    } else if (node is dom.Element) {
      TextStyle newStyle = currentStyle;
      switch (node.localName) {
        case 'b':
        case 'strong':
          newStyle = newStyle.copyWith(fontWeight: FontWeight.bold);
          break;
        case 'i':
        case 'em':
          newStyle = newStyle.copyWith(fontStyle: FontStyle.italic);
          break;
        case 'u':
          newStyle = newStyle.copyWith(decoration: TextDecoration.underline);
          break;
        case 'font':
          final colorAttr = node.attributes['color'];
          if (colorAttr != null) {
            final color = _parseColor(colorAttr);
            if (color != null) {
              newStyle = newStyle.copyWith(color: color);
            }
          }
          break;
        case 'br':
          spans.add(const TextSpan(text: '\n'));
          return spans;
        case 'hr':
          spans.add(
            WidgetSpan(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                height: 1.0,
                color: Colors.grey,
              ),
            ),
          );
          return spans;
        case 'a':
          // Link handling
          final href = node.attributes['href'] ?? '';
          TapGestureRecognizer tapRecognizer = TapGestureRecognizer()
            ..onTap = () {
              if (widget.onLinkTap != null) {
                widget.onLinkTap!(href);
              }
            };
          List<InlineSpan> linkSpans = [];
          int currentOffsetForLink = offset;
          for (var child in node.nodes) {
            List<InlineSpan> childSpans = _parseNodeToSpansWithHighlights(
              child,
              newStyle.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
              currentOffsetForLink,
              globalHighlights,
            );
            linkSpans.addAll(childSpans);
            String childText = _flattenInlineSpans(childSpans);
            currentOffsetForLink += childText.length;
          }
          spans.add(
            TextSpan(
              children: linkSpans,
              style: newStyle.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
              recognizer: tapRecognizer,
            ),
          );
          return spans;
      }

      // Parse child nodes recursively
      int currentOffset = offset;
      for (var child in node.nodes) {
        List<InlineSpan> childSpans = _parseNodeToSpansWithHighlights(
          child,
          newStyle,
          currentOffset,
          globalHighlights,
        );
        spans.addAll(childSpans);
        String childPlain = _flattenInlineSpans(childSpans);
        currentOffset += childPlain.length;
      }
      return spans;
    }

    return spans;
  }

  /// Shows a dialog when a highlighted segment is tapped, displaying the note if any.
  void _showSpanDialog(BuildContext context, String spanContent, String note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note.isNotEmpty ? note : 'No note', style: const TextStyle(fontSize: 18.0)),
        content: SelectableText(spanContent),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: '$spanContent\n\n${note.isNotEmpty ? note : "No note"}'),
              );
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
