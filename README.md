# Flutter HTML Viewer

A Flutter package for displaying HTML content with highlights, selection controls, and customizable UI for note-taking or annotations. This library started as a "book reader" approach, but has now been refactored into a **generic HTML reading** solution where references to books have been replaced by a single `metaData` field.

## Key Features

- **Render HTML**: Supports parsing basic HTML tags (`b`, `i`, `u`, `a`, `hr`, `br`, etc.) into Flutter `InlineSpan`s.
- **Highlight Text**: Allows applying highlights (with customizable colors) to any portion of the displayed text.
- **Notes / Annotations**: You can attach notes to highlighted sections, which appear underlined if present.
- **Custom Selection Toolbar**: A fully customizable `CustomTextSelectionControls` that provides search actions, highlight button, copy & share, and a button to add notes.
- **RTL/LTR Support**: You can set `TextDirection` for your entire HTML content.
- **Pluggable Highlight UI**: By default, a `HighlightBottomSheet` is provided, but you can replace it with your own UI via `highlightSheetBuilder` or `onHighlightRequested`.
- **Metadata**: A single `metaData` field allows you to pass any extra data (e.g., doc info, user info) without referencing a specific "book" concept.

## Quick Example

```dart
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
    // Define custom text selection controls
    final selectionControls = CustomTextSelectionControls(
      metaData: {'title': 'My Document'},
      pageNumber: 1,
      fullPageText: "<p>Hello <b>World</b> from example!</p>",
      onHighlightDone: () => print("Highlight done!"),

      // Example search callbacks
      onSearchInContent: (text) => print("Search in Content: $text"),
      onSearchInGoogle: (text) => print("Search in Google: $text"),
      onSearchInDictionary: (text) => print("Search in Dictionary: $text"),
      onSearchInBing: (text) => print("Search in Bing: $text"),

      // If you want to replace the default bottom sheet with your own:
      // highlightSheetBuilder: (ctx, request) {
      //   return MyCustomHighlightSheet(request: request);
      // },

      // Or handle highlight entirely yourself:
      // onHighlightRequested: (request) {
      //   // showDialog(...) or any custom approach
      // },
    );

    return Scaffold(
      appBar: AppBar(title: const Text("HTML Viewer Example")),
      body: HtmlViewer(
        metaData: {'title': 'My Document'},
        pageNumber: 1,          
        htmlContent: "<h1>Hello <em>World</em></h1><p>This is a sample HTML content.</p>",
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
        onLinkTap: (url) => print("Link tapped: $url"),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
```

## Main Classes

1. **`HtmlViewer`**  
   Core widget that displays HTML content, applies highlights, and hooks in custom selection controls.

2. **`CustomTextSelectionControls`**  
   A subclass of `MaterialTextSelectionControls` that adds extra toolbar items (search, highlight, share, etc.) and the logic to show bottom sheets or dialogs for highlights.

3. **`HighlightBottomSheet`**  
   The default bottom sheet UI for highlight color selection and note-taking. You can replace it by providing a `highlightSheetBuilder` or `onHighlightRequested`.

4. **`HighlightRange`**  
   A simple model representing the start/end index of a highlight, along with color and note text.

5. **`HighlightRequest`**  
   A data model used when you tap "Highlight" in the selection toolbar. Contains `metaData`, `pageNumber`, the selected text, etc. so your custom UI can handle it.

## Parameters for `HtmlViewer`

| Parameter               | Type                          | Description                                                                                                 |
|-------------------------|-------------------------------|-------------------------------------------------------------------------------------------------------------|
| **metaData**           | `dynamic`                     | A generic field for any extra info (replaces old book references).                                          |
| **pageNumber**         | `int`                         | If you need to track page references or indexing; otherwise can be ignored or set to 0.                     |
| **htmlContent**        | `String`                      | The raw HTML string to parse and render.                                                                    |
| **fontFamily**         | `String`                      | The font family for displayed text (e.g., `"Arial"`).                                                       |
| **fontSize**           | `double`                      | Font size for the entire rendered text.                                                                     |
| **textColor**          | `Color`                       | Base text color.                                                                                            |
| **lineHeight**         | `double`                      | The spacing between lines (leading).                                                                        |
| **backgroundColor**    | `Color`                       | The background color for the container that holds the text.                                                 |
| **textAlign**          | `TextAlign`                   | e.g., left, right, center, justify.                                                                         |
| **context**            | `BuildContext`                | Flutter context, if needed for showing dialogs or toolbars.                                                 |
| **selectionControls**  | `TextSelectionControls`       | Typically `CustomTextSelectionControls`, which brings search/highlight UI.                                  |
| **searchHighlights**   | `List<Map<String, dynamic>>?` | If you want to highlight certain keywords or search terms automatically. Pass them here.                    |
| **userHighlights**     | `List<HighlightRange>`        | A list of user-defined highlights with color, note, etc.                                                    |
| **onLinkTap**          | `(String) -> void`            | A callback to handle `<a href="...">` taps. If null, links are inert.                                       |
| **textDirection**      | `TextDirection`               | Sets RTL or LTR. Default is `TextDirection.ltr`.                                                            |

## Parameters for `CustomTextSelectionControls`

| Parameter              | Type                                      | Description                                                                     |
|------------------------|-------------------------------------------|---------------------------------------------------------------------------------|
| **metaData**          | `dynamic`                                 | Generic data (replacing old book references).                                   |
| **pageNumber**        | `int`                                     | Page index or any numeric reference.                                            |
| **fullPageText**      | `String`                                  | The entire text content for indexing.                                          |
| **onHighlightDone**   | `VoidCallback`                            | Called when a highlight is saved or finished.                                  |
| **onSearchInContent** | `(String) -> void`                        | Callback for searching the selected text in your "content".                    |
| **onSearchInGoogle**  | `(String) -> void`                        | Callback for searching in Google.                                              |
| **onSearchInDictionary** | `(String) -> void`                     | Callback for searching in a dictionary.                                        |
| **onSearchInBing**    | `(String) -> void`                        | Callback for searching in Bing.                                                |
| **highlightSheetBuilder** | `HighlightSheetBuilder?`               | If set, shows a custom bottom sheet (replacing the default `HighlightBottomSheet`). |
| **onHighlightRequested** | `(HighlightRequest request) -> void`    | If set, handle highlight entirely yourself. No default bottom sheet is shown.  |

## How Highlighting Works

1. **Selecting Text**  
   The user taps and holds on the text, then drags to select. The custom selection toolbar (provided by `CustomTextSelectionControls`) appears.

2. **Pressing "Highlight"**
    - By default, it calls the logic in `custom_text_selection_controls.dart` which will either:
        1. Call `onHighlightRequested` if defined, letting you handle everything yourself.
        2. Call `highlightSheetBuilder` if provided, letting you build a custom UI (e.g., a bottom sheet).
        3. Otherwise, show the default `HighlightBottomSheet`.

3. **HighlightBottomSheet**
    - Allows picking a highlight color and adding an optional note.
    - On saving (`onSaved` callback), the highlight is stored or processed in your DB/model (you can customize).

4. **Re-rendering**
    - The library merges `userHighlights` with `searchHighlights` to highlight text. If you want new highlights to appear, you need to update these lists and rebuild `HtmlViewer`.

## Customizing or Replacing the Bottom Sheet

- **Using `highlightSheetBuilder`**
  ```dart
  CustomTextSelectionControls(
    metaData: {...},
    pageNumber: 1,
    fullPageText: "...",
    onHighlightDone: () => print("Done"),
    onSearchInContent: (text) => print("Search in Content: $text"),
    onSearchInGoogle: (text) => print("Search in Google: $text"),
    onSearchInDictionary: (text) => print("Search in Dictionary: $text"),
    onSearchInBing: (text) => print("Search in Bing: $text"),
    highlightSheetBuilder: (ctx, request) {
      return MyOwnBottomSheetUI(request: request);
    },
  );
  ```

- **Using `onHighlightRequested`**
  ```dart
  CustomTextSelectionControls(
    metaData: {...},
    pageNumber: 1,
    fullPageText: "...",
    onHighlightDone: () => print("Done"),
    onSearchInContent: (text) => print("Search in Content: $text"),
    onSearchInGoogle: (text) => print("Search in Google: $text"),
    onSearchInDictionary: (text) => print("Search in Dictionary: $text"),
    onSearchInBing: (text) => print("Search in Bing: $text"),

    onHighlightRequested: (request) {
      // Show your own dialog, or do any custom flow
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Your custom highlight UI"),
          content: Text("Selected text: ${request.selectedText}"),
          // ...
        ),
      );
    },
  );
  ```

In both methods, you gain full control over how the highlight is performed, stored, or presented to the user.

## Example Project

There's an [`example/`](./example) folder alongside this library that demonstrates how to integrate `flutter_html_viewer` in a real Flutter app. To try it:

1. Clone the repo.
2. `cd example`
3. `flutter pub get`
4. `flutter run`

You'll see a minimal Flutter app using `HtmlViewer` and custom text selection controls.

## Contributing

Contributions and pull requests are welcome! Please open an issue first to discuss the proposed changes. For major changes, please open a discussion or pull request early so we can coordinate.

## License

This project is licensed under the [MIT License](./LICENSE).
