# FORMATUS

A plain Flutter Rich-Text-Editor without any dependencies.

## Features

* Runs on all platforms
* Supports multiple section and inline formats
* Small and easy to use
* No dependencies to other packages
* Includes a viewer for the formatted text

## Getting started

Add the latest version of *Formatus* to the `pubspec.yaml` file:

```yaml
flutter:
  formatus: ^1.2.0
```

Create a `FormatusController` and a `FormatusBar`.
Supply a `FocusNode` to both the `FormatusBar` and the `TextField` (or `TextFormField`).


## Usage

Use `Formatus` like this:

```dart
  FocusNode focusNode = FocusNode(debugLabel: 'formatus');
  late FormatusController controller;
  String savedText = '<p>some text</p>';

void initState() {
  controller = FormatusController( formattedText: savedText, onChanged: (v) => savedText = v );
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

Caret
: visible display of the cursor position 

Format
: All text has a format. Its format is specified by the section format and all inline formats applied to the text

Section
: All text belongs to a section. Each section has a format. Multiple sections are separated by a newline


### Use cases

This section describes the use cases for `Formatus`.

* Position caret -> updates `FormatusBar` with formats at caret position
* Select a text range -> updates `FormatusBar` with formats from selection start
* Activate another section-format in `FormatusBar`
  -> the current section (defined by caret position or start of a selected text-range)
  will be changed to the activated section-format
* Change an inline-format in `FormatusBar` -> if a text range is selected
  then the selected text will be updated with the new format
* Enter characters (via keyboard or by pasting from a clipboard) -> characters
  will be inserted at caret position. Current format settings will be applied
* Delete characters -> if this includes one or more (requires a text-range)
  line-breaks then the text right of the deleted text will be integrated
  into the top-level node at deletion start
* Display the formatted text with `FormatusViewer`

## Additional information

Please find additional information like architecture considerations at
https://www.djarjo.com/formatus

If you encounter any issues or have ideas for some enhancements please
open a ticket at https://github.com/hlemcke/formatus


## Future Enhancements

1. Add format for superscript
2. Add format for subscript
3. Add format to change text color
4. Add format to change text color
5. Add format for unordered list
6. Add format for ordered list (auto-counting)
7. Add action to insert an emoji. This should become an optional add-on action
   similar to `FormatusAnchor`. Could also include converting an emoji name
   into emoji inline (insert into current text node).
8. Parse markdown as formatted input
9. Export formatted text in markdown format
