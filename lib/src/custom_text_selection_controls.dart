import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'highlight_bottom_sheet.dart';

/// Represents highlight request info.
class HighlightRequest {
  /// just a metaData
  final dynamic metaData;

  /// Optional page number if you still need it
  final int pageNumber;

  /// Full page text for indexing or footnotes
  final String fullPageText;

  /// Start & end index in the text
  final int startIndex;
  final int endIndex;

  /// The selected text segment
  final String selectedText;

  HighlightRequest({
    required this.metaData,
    required this.pageNumber,
    required this.fullPageText,
    required this.startIndex,
    required this.endIndex,
    required this.selectedText,
  });
}

/// A builder function that creates a custom bottom sheet (or any widget) to handle highlight.
typedef HighlightSheetBuilder = Widget Function(
    BuildContext context,
    HighlightRequest highlightRequest,
    );

/// A callback if you want to handle highlight logic entirely yourself.
typedef OnHighlightRequested = void Function(HighlightRequest request);

/// A custom selection controls class that shows a toolbar with highlight, search, share, copy, etc.
class CustomTextSelectionControls extends MaterialTextSelectionControls {
  /// a single metaData
  final dynamic metaData;

  /// Optional pageNumber if still needed
  final int pageNumber;

  /// The full text content
  final String fullPageText;

  /// Called whenever a highlight is successfully done
  final VoidCallback onHighlightDone;

  /// Searching callbacks for external engines
  final Function(String) onSearchInContent;
  final Function(String) onSearchInGoogle;
  final Function(String) onSearchInDictionary;
  final Function(String) onSearchInBing;

  /// If provided, you can display a custom bottom sheet for highlights
  final HighlightSheetBuilder? highlightSheetBuilder;

  /// If provided, you can handle highlight yourself without showing a default UI
  final OnHighlightRequested? onHighlightRequested;

  CustomTextSelectionControls({
    required this.metaData,
    required this.pageNumber,
    required this.fullPageText,
    required this.onHighlightDone,
    required this.onSearchInContent,
    required this.onSearchInGoogle,
    required this.onSearchInDictionary,
    required this.onSearchInBing,
    this.highlightSheetBuilder,
    this.onHighlightRequested,
  });

  bool _isSingleWord(String text) {
    return text.trim().split(RegExp(r'\s+')).length == 1;
  }

  @override
  Widget buildToolbar(
      BuildContext context,
      Rect globalEditableRegion,
      double textLineHeight,
      Offset position,
      List<TextSelectionPoint> endpoints,
      TextSelectionDelegate delegate,
      ValueListenable<ClipboardStatus>? clipboardStatus,
      Offset? lastSecondaryTapDownPosition,
      ) {
    // Calculate position
    final baseOffset = globalEditableRegion.topLeft + position;
    final textSelection = delegate.textEditingValue.selection;
    final originalText = delegate.textEditingValue.text;

    final adjustedIndexes = _adjustSelectionIndexes(originalText, textSelection.start, textSelection.end);
    final adjustedStart = adjustedIndexes['start']!;
    final adjustedEnd = adjustedIndexes['end']!;
    final selectedText = originalText.substring(textSelection.start, textSelection.end);

    final isSingle = _isSingleWord(selectedText);

    final screenSize = MediaQuery.of(context).size;
    const toolbarMargin = 8.0;
    double left = baseOffset.dx;
    double top = baseOffset.dy - 85;
    const estimatedToolbarWidth = 300.0;
    const estimatedToolbarHeight = 85.0;

    // Keep the toolbar within screen bounds
    if (left + estimatedToolbarWidth + toolbarMargin > screenSize.width) {
      left = screenSize.width - estimatedToolbarWidth - toolbarMargin;
    }
    if (left < toolbarMargin) {
      left = toolbarMargin;
    }
    if (top < toolbarMargin) {
      top = toolbarMargin;
    }
    if (top + estimatedToolbarHeight + toolbarMargin > screenSize.height) {
      top = screenSize.height - estimatedToolbarHeight - toolbarMargin;
    }

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 4,
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      tooltip: 'Search',
                      color: Colors.white,
                      icon: const Icon(Icons.search, color: Colors.white),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () {
                            onSearchInContent(selectedText);
                          },
                          value: 'content',
                          child: const Text(
                            'Search in content',
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () {
                            onSearchInGoogle(selectedText);
                          },
                          value: 'google',
                          child: const Text(
                            'Search in Google',
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () {
                            onSearchInBing(selectedText);
                          },
                          value: 'bing',
                          child: const Text(
                            'Search in Bing',
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ),
                        if (isSingle)
                          PopupMenuItem(
                            onTap: () {
                              onSearchInDictionary(selectedText);
                            },
                            value: 'dictionary',
                            child: const Text(
                              'Search in Dictionary',
                              style: TextStyle(color: Colors.black87, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Highlight',
                      icon: const Icon(Icons.create, color: Colors.white),
                      onPressed: () {
                        delegate.hideToolbar();

                        final request = HighlightRequest(
                          metaData: metaData,
                          pageNumber: pageNumber,
                          fullPageText: fullPageText,
                          startIndex: adjustedStart,
                          endIndex: adjustedEnd,
                          selectedText: selectedText,
                        );

                        if (onHighlightRequested != null) {
                          onHighlightRequested!(request);
                          return;
                        }

                        if (highlightSheetBuilder != null) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) {
                              return highlightSheetBuilder!(ctx, request);
                            },
                          );
                          return;
                        }

                        // default bottom sheet
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) {
                            return HighlightBottomSheet(
                              metaData: metaData,      // replaced
                              pageNumber: pageNumber,  // still using
                              fullPageText: fullPageText,
                              startIndex: adjustedStart,
                              endIndex: adjustedEnd,
                              selectedText: selectedText,
                              onSaved: () {
                                onHighlightDone();
                                delegate.hideToolbar();
                              },
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () async {
                        final value = delegate.textEditingValue;
                        final start = value.selection.start;
                        final end = value.selection.end;
                        final text = value.text.substring(start, end);

                        await Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                        delegate.hideToolbar();
                      },
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    delegate.hideToolbar();

                    final request = HighlightRequest(
                      metaData: metaData, // replaced
                      pageNumber: pageNumber,
                      fullPageText: fullPageText,
                      startIndex: adjustedStart,
                      endIndex: adjustedEnd,
                      selectedText: selectedText,
                    );

                    if (onHighlightRequested != null) {
                      onHighlightRequested!(request);
                      return;
                    }
                    if (highlightSheetBuilder != null) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) {
                          return highlightSheetBuilder!(ctx, request);
                        },
                      );
                      return;
                    }

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) {
                        return HighlightBottomSheet(
                          metaData: metaData,
                          pageNumber: pageNumber,
                          fullPageText: fullPageText,
                          startIndex: adjustedStart,
                          endIndex: adjustedEnd,
                          selectedText: selectedText,
                          onSaved: () {
                            onHighlightDone();
                            delegate.hideToolbar();
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[700]!)),
                    ),
                    child: const Text(
                      "Add Note ...",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Adjust selection indexes if newlines are removed
  Map<String, int> _adjustSelectionIndexes(String text, int start, int end) {
    int adjustedStart = start;
    int adjustedEnd = end;
    int removedNewlinesBeforeStart = 0;
    int removedNewlinesBeforeEnd = 0;

    for (int i = 0; i < text.length; i++) {
      if (i < start && text[i] == '\n') {
        removedNewlinesBeforeStart++;
      }
      if (i < end && text[i] == '\n') {
        removedNewlinesBeforeEnd++;
      }
    }
    adjustedStart -= removedNewlinesBeforeStart;
    adjustedEnd -= removedNewlinesBeforeEnd;
    return {
      'start': adjustedStart,
      'end': adjustedEnd,
    };
  }
}
