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

## Additional information

Please find additional information like architecture considerations at
https://formatus.djarjo.com

If you encounter any issues or have ideas for some enhancements please
open a ticket at github (TODO suppy link)

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

# Enhancements

1. Apply format action to a range of text
2. Add action to insert an emoji
3. Convert emoji name into emoji inline => insert into current text node
4. Add action to insert an image
5. Add action to insert a link (URL entered in alert dialog)
6. Add formats for lists: ordered and unordered
7. Parse and export markdown
8. Add format action to change alignment of all text to: left (default), center, right
