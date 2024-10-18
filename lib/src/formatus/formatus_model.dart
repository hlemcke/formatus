import 'package:flutter/material.dart';

import 'text_helper.dart';

const double kDefaultFontSize = 14.0;

///
/// Formats for:
/// * elements (both top-level and inline)
/// * attributes (like color)
///
/// Each entry provides default values for [FormatusAction] widget
/// and display format.
///
enum Formatus {
  /// Outer format to align all text in the center
  alignCenter(
    'align="center"',
    FormatusType.alignment,
    Icon(Icons.format_align_center),
    null,
  ),

  /// Outer format to justify all text within the width of the text field
  alignJustify(
    'align="justify"',
    FormatusType.alignment,
    Icon(Icons.format_align_justify),
    null,
  ),

  /// Outer format to align all text left
  alignLeft(
    'align="left"',
    FormatusType.alignment,
    Icon(Icons.format_align_left),
    null,
  ),

  /// Outer format to align all text right
  alignRight(
    'align="right"',
    FormatusType.alignment,
    Icon(Icons.format_align_right),
    null,
  ),

  /// Inline format to display bold text
  bold(
    'b',
    FormatusType.inline,
    Icon(Icons.format_bold),
    TextStyle(fontWeight: FontWeight.bold),
  ),

  /// Attribute of any top-level or inline element sets color
  color(
    'color=',
    FormatusType.attribute,
    Icon(Icons.format_color_text),
    null,
  ),

  /// Top level element header 3 (largest)
  header1(
    'h1',
    FormatusType.topLevel,
    Text(
      'H1',
      style: TextStyle(
        fontSize: kDefaultFontSize * 1.2,
        fontWeight: FontWeight.bold,
      ),
    ),
    TextStyle(
      fontSize: kDefaultFontSize * 2.0,
      height: 2.0,
    ),
  ),

  /// Top level element header 2 (larger)
  header2(
      'h2',
      FormatusType.topLevel,
      Text(
        'H2',
        style: TextStyle(
          fontSize: kDefaultFontSize * 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      TextStyle(fontSize: kDefaultFontSize * 1.7)),

  /// Top level element header 3 (large)
  header3(
      'h3',
      FormatusType.topLevel,
      Text(
        'H3',
        style: TextStyle(
          fontSize: kDefaultFontSize * 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      TextStyle(fontSize: kDefaultFontSize * 1.4)),

  /// Splits text at current cursor position and inserts a horizontal ruler
  horizontalRule('hr', FormatusType.topLevel, Text('-'), null),

  /// Inline element to italicize text
  italic(
    'i',
    FormatusType.inline,
    Icon(Icons.format_italic),
    TextStyle(fontStyle: FontStyle.italic),
  ),

  /// Splits text at cursor position and inserts an image selected
  /// from an `ImageSelector`
  image(
    'img',
    FormatusType.inline,
    Icon(Icons.image_outlined),
    TextStyle(
      color: Colors.deepPurpleAccent,
      decoration: TextDecoration.underline,
    ),
  ),

  /// An html anchor element:
  /// ```
  /// <a href="url">displayed text</a>
  /// ```
  /// Text is displayed purple and underlined.
  /// The URL is displayed as a tooltip when hovering above the text.
  link(
    'a',
    FormatusType.inline,
    Icon(Icons.link),
    TextStyle(color: Colors.purpleAccent, decoration: TextDecoration.underline),
  ),

  /// Essentially one of the `li` elements of the enclosing `ol` element
  orderedList(
    'ol',
    FormatusType.topLevel,
    Icon(Icons.format_list_numbered),
    null,
  ),

  /// Contains text and other inline elements
  paragraph(
    'p',
    FormatusType.topLevel,
    Text(
      'P',
      style: TextStyle(
        fontSize: kDefaultFontSize * 1.2,
        fontWeight: FontWeight.bold,
      ),
    ),
    TextStyle(fontSize: kDefaultFontSize),
  ),

  /// Inline format to strike through text
  strikeThrough(
    's',
    FormatusType.inline,
    Icon(Icons.format_strikethrough),
    TextStyle(decoration: TextDecoration.lineThrough),
  ),

  /// plain text node -> format derived from parent nodes
  text('', FormatusType.inline, null, null),

  /// Inline format to underline text
  underline(
    'u',
    FormatusType.inline,
    Icon(Icons.format_underline),
    TextStyle(decoration: TextDecoration.underline),
  ),

  /// Essentially one of the `li` elements of the enclosing `ul` element
  unorderedList(
    'ul',
    FormatusType.topLevel,
    Icon(Icons.format_list_bulleted),
    null,
  );

  final String key;
  final FormatusType type;
  final Widget? icon;
  final TextStyle? style;

  const Formatus(
    this.key,
    this.type,
    this.icon,
    this.style,
  );

  bool get isTopLevel => type == FormatusType.topLevel;

  static Formatus find(String text) =>
      TextHelper.findEnum(text, Formatus.values,
          defaultValue: Formatus.text, withKey: true);
}

///
/// Type of a [Formatus] action / style
///
enum FormatusType {
  /// Alignment will be applied to full text
  alignment,

  /// Attribute are applied to an element
  attribute,

  /// Inline elements can be nested
  inline,

  /// Top level elements can only contain `inline` elements
  topLevel,
}
