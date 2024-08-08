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

A Flutter plain Rich-Text-Editor without any dependencies.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

Add the latest version of `formatus` to your `pubspec.yaml` file:

```yaml
flutter:
  formatus: ^1.0.1
```

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart

const FocusNode formatusFocs = FocusNode(debugLabel: 'formatus');
FormatusController formatusController = FormatusController.fromHtml('');

```

## Additional information

Please find additional information like architecture considerations at
https://formatus.djarjo.com

If you encounter any issues or have ideas for some enhancements please
open a ticket at github (TODO suppy link)

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

# TODO

1. Use current setting of format actions when entering new text
2. Apply format action to a range of text
3. Apply deletion to a range of text. This may include deletion of nodes.
4. Add action to insert an emoji
5. Add action to insert an image
6. Add action to insert a link (URL entered in alert dialog)
7. Parse and export markdown

## Markdown

The `Formatus` editor also supports `Markdown`. Following elements are supported:

* `Heading` -> `# heading1`, `## heading 2`, `### heading 3`
* `Italic`  -> `*italic text*`
* `Bold`    -> `**bold text**`
* `Underline` -> `_underlined text_`
* `Line through` -> `~~lined through text~~`
* `Subscript` -> `H~2~O`
* `Superscript` -> `a^2^ + b^2^ = c^2^`
* `Horizontal rule` -> `---` as a single line with an empty line above
* `Link` -> `[title](https://formatus.github.com)`
* `Ordered list` -> `1. First item`
* `Unordered list` -> `* item`
* `Emoji` -> `That's funny :joy:` renders an emoji by its name
* `Task list` -> `[x] completed\n[ ] still open`
