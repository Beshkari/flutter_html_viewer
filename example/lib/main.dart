import 'package:flutter/material.dart';
import 'package:flutter_html_viewer/flutter_html_viewer.dart';

void main() {
  runApp(const MyExampleApp());
}

class MyExampleApp extends StatelessWidget {
  const MyExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_html_viewer Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyExampleHomePage(),
    );
  }
}

class MyExampleHomePage extends StatelessWidget {
  const MyExampleHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define a simple text selection control
    final selectionControls = CustomTextSelectionControls(
      metaData: {'title': 'Example Document'},
      pageNumber: 1,
      fullPageText: "<p>Hello <b>World</b> from example!</p>",
      onHighlightDone: () => print("Highlight done!"),
      onSearchInContent: (text) => print("Search in Book: $text"),
      onSearchInGoogle: (text) => print("Search in Google: $text"),
      onSearchInDictionary: (text) => print("Search in Dictionary: $text"),
      onSearchInBing: (text) => print("Search in Bing: $text"),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('HTML Viewer Example')),
      body: HtmlViewer(
        metaData: {'title': 'Example Document'},
        pageNumber: 1,
        htmlContent: "<h1>Welcome to <em>flutter_html_viewer</em> example!</h1>"
            "<p>This is a sample <strong>HTML</strong> content.</p>",
        fontFamily: 'Arial',
        fontSize: 16,
        textColor: Colors.black,
        lineHeight: 1.5,
        backgroundColor: Colors.white,
        textAlign: TextAlign.left,
        context: context,
        selectionControls: selectionControls,
        searchHighlights: [],
        userHighlights: [],
      ),
    );
  }
}
