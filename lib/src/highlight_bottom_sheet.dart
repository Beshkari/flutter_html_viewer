import 'package:flutter/material.dart';

/// A default bottom sheet to handle highlight creation.
class HighlightBottomSheet extends StatefulWidget {
  final dynamic metaData;
  final int pageNumber;
  final String fullPageText;
  final int startIndex;
  final int endIndex;
  final String selectedText;

  /// Called after highlight is saved
  final VoidCallback onSaved;

  const HighlightBottomSheet({
    Key? key,
    required this.metaData,
    required this.pageNumber,
    required this.fullPageText,
    required this.startIndex,
    required this.endIndex,
    required this.selectedText,
    required this.onSaved,
  }) : super(key: key);

  @override
  _HighlightBottomSheetState createState() => _HighlightBottomSheetState();
}

class _HighlightBottomSheetState extends State<HighlightBottomSheet> {
  final List<Map<String, dynamic>> colorsHex = [
    {'id': '1', 'color': '#ffdc8e'},
    {'id': '2', 'color': '#fcb495'},
    {'id': '3', 'color': '#c0e09b'},
    {'id': '4', 'color': '#8ae1eb'},
  ];

  String selectedColor = '1';
  TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Highlight:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Text(widget.selectedText),
            ),
            const SizedBox(height: 10),
            const Text('Select Highlight Color:'),
            const SizedBox(height: 8),
            Row(
              children: colorsHex.map((cHex) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = cHex['id'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _parseColor(cHex['color']),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == cHex['id'] ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Save highlight logic
                // metaData can be used if needed
                // example:
                // final db = MyDatabase();
                // db.insertHighlight(
                //   metaData: widget.metaData,
                //   page: widget.pageNumber,
                //   startIndex: widget.startIndex,
                //   endIndex: widget.endIndex,
                //   color: selectedColor,
                //   note: noteController.text,
                // );
                widget.onSaved();
                Navigator.pop(context);
              },
              child: const Text('Submit Highlight'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    String newColor = hexColor.replaceAll('#', '');
    if (newColor.length == 6) {
      newColor = 'FF$newColor';
    }
    return Color(int.parse(newColor, radix: 16));
  }
}
