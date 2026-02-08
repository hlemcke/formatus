# FORMATUS

A plain Flutter Rich-Text-Editor without any dependencies

## Features

* Runs on all platforms
* Small and easy to use
* Directly integrates into `TextField` and `TextFormField`
* No dependencies to other packages to keep it small and lightweight
* Supports multiple section and inline formats
* Includes a viewer for the formatted text
* `FormatusBar` provides multiple callbacks to integrate your favorite packages

## Getting started

Add the latest version of *Formatus* to the `pubspec.yaml` file:

```yaml
flutter:
  formatus: ^2.1.0
```

Follow these steps:

1. create a `FormatusController`
2. create a `FocusNode`
3. supply both `FormatusController` and `FocusNode` to the `FormatusBar` and the `TextField`

## Usage

Use `Formatus` like this:

```dart
  FocusNode _formatusFocus = FocusNode(debugLabel: 'formatus');
  late FormatusController controller;
  String savedText = '';

void initState() {
  controller = FormatusController( formattedText: savedText,
      onChanged: (v) => setState(() => savedText = v ),);
}

Widget build(BuildContext context) => Column( children: [
  FormatusBar(
    controller: controller,
    hideInactive: true,
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

### Emojis

`Formatus` has an action `emoji`. The button will become available as soon as an
emoji selector callback is provided to `FormatusBar`. If only a small number
of emojis is required then this approach is sufficient:

```
FormatusBar( ...,
          onSelectEmoji: (context) async => await showDialog<String>(
            context: context, builder: (context) => Dialog(
              child: Wrap( children: ['😀', '🚀', '✅'].map( (e) => IconButton(
                        icon: Text(e), onPressed: () => Navigator.pop(context, e),
                      ), ).toList(), ), ), ),
```

A full emoji package like [emoji_picker_flutter](https://pub.dev/emoji_picker_flutter)
can also be integrated easily:

``` Dart
FormatusBar( ...,
          onSelectEmoji: (context) => showEmojiSelector(), );
          
Future<String?> showEmojiSelector() async =>
  showAdaptiveDialog(context: context, builder: (BuildContext context) =>
    Dialog( child: EmojiPicker(textEditingController: controller, ), ), );
```

## FAQ

- **Q**: I can only enter one line of text. Enter does not work.
  **A**: Supply `minLines: 2` or a larger value to `TextFormField`


## Supported Formats

* __H1__ → Header 1 with largest font size
* __H2__ → Header 2 with larger font size
* __H3__ → Header 3 with large font size
* __P__ → Paragraph with standard font size
* __OL__ → Ordered list
* __UL__ → Unordered list
* __B__ → bold text
* __I__ → italicized text
* __U__ → underlined text
* __S__ → strike-through text
* __sub__ → subscript text
* __sup__ → superscript text
* __color__ → text coloring


## 🔗 Project Links

- 🌐 [Homepage](https://www.djarjo.com/formatus)
- 🐛 [Issue Tracker](https://github.com/hlemcke/formatus/issues)
- 📚 [Documentation](https://www.djarjo.com/formatus/docs)
- 🗂️ [Repository](https://github.com/hlemcke/formatus)


## Enhancements

* implement undo / redo functionality
* parse Markdown format as input
* optimize formatting tree by reshaking

For an additional enhancement request please open an issue.


## Known Deficiencies

1. Horizontal ruler not yet implemented
2. Coloring is restricted to 19 included colors
3. Line-breaks in pasted text are replaced by spaces
4. Lists cannot be nested
5. Subscript and superscript are displayed correctly only in [FormatusViewer] because Flutter
   [TextField] and [TextFormField] do not support their editing

## User Manual

### Definition of Terms

Caret
: visible display of the cursor position 

Format
: All text has a format. Its format is specified by the section format and all inline formats applied to the text

Section
: All text belongs to a section. Each section has a format. Multiple sections are separated by a newline


### Use cases

This section describes the use cases for `Formatus`.

* Position caret → updates `FormatusBar` with formats at caret position
* Select a text range → updates `FormatusBar` with formats from selection start
* Activate another section-format in `FormatusBar`
  → the current section (defined by caret position or start of a selected text-range)
  will be changed to the activated section-format
* Change an inline-format in `FormatusBar` → if a text range is selected
  then the selected text will be updated with the new format
* Enter characters (via keyboard or by pasting from a clipboard) → characters
  will be inserted at caret position. Current format settings will be applied
* Delete characters → if this includes one or more (requires a text-range)
  line-breaks then the text right of the deleted text will be integrated
  into the top-level node at deletion start
* Display the formatted text with `FormatusViewer`


## Additional information

Please find additional information like architecture considerations at
https://www.djarjo.com/formatus

If you encounter any issues or have ideas for some enhancements please
open a ticket at https://github.com/hlemcke/formatus
