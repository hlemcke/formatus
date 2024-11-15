<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# FORMATUS

A plain Flutter Rich-Text-Editor without any dependencies.

## Features

* Supports multiple top-level and inline formats
* Easy to use
* No dependencies to other packages

## Getting started

Add the latest version of `formatus` to your `pubspec.yaml` file:

```yaml
flutter:
  formatus: ^1.0.1
```

Create a [FormatusController] and a [FormatusBar].
Supply a [FocusNode] to both the [FormatusBar] and the [TextField].


## Usage

Use `Formatus` like this:

```dart
  FocusNode focusNode = FocusNode(debugLabel: 'formatus');
  late FormatusController controller;

void initState() {
  controller = FormatusController.fromFormattedText( text );
}

Widget build(BuildContext context) => Column( children: [
  FormatusBar(
    controller: controller,
    textFieldFocus: _formatusFocus,
  ),
  TextFormField(
    controller: controller,
    focusNode: _formatusFocus,
    minLines: 3,
    maxLines: 10 ),
  ]);

//--- Don't forget the standard dispose of the controller
void dispose() {
  controller.dispose();
}
```

## User Manual

### Definition of Terms

### Use cases

This section describes the use cases for `Formatus`.

* Position caret -> updates [FormatusBar] with formats at caret position
* Select a text range -> updates [FormatusBar] with formats from selection start
* Activate another top-level format in [FormatusBar]
  -> the current section (at caret position or at start of a selected text-range)
  will be changed to the activated top-level format
* Change an inline format in [FormatusBar] -> if a text range is selected
  then the selected text will be updated with the new format
* Enter characters (via keyboard or by pasting from a clipboard) -> characters
  will be inserted at caret position. Current format settings will be applied.
* Delete characters -> if this includes one or more (requires a text-range)
  line-breaks then the text right of the deleted text will be integrated
  into the top-level node at deletion start

## Additional information

Please find additional information like architecture considerations at
https://formatus.djarjo.com

If you encounter any issues or have ideas for some enhancements please
open a ticket at github (TODO suppy link)

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

## Enhancements

1. Add formats for lists: ordered and unordered
2. Add action to change a color
3. Add action to insert an emoji. This should become an optional add-on action
   similar to `FormatusAnchor`. Could also include converting an emoji name
   into emoji inline (insert into current text node).
4. Parse and export markdown
5. Add format action to change alignment of all text to: left (default), center, right
6. Integrate an option to work with right-to-left languages
