import 'package:flutter/material.dart';

import 'formatus_document.dart';

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

  /// An html anchor element:
  /// ```
  /// <a href="url">displayed text</a>
  /// ```
  /// Text is displayed purple and underlined.
  /// The URL is displayed as a tooltip when hovering above the text.
  ///
  /// See [FormatusAnchor]
  anchor(
    'a',
    FormatusType.inline,
    Icon(Icons.link),
    TextStyle(color: Colors.purpleAccent, decoration: TextDecoration.underline),
  ),

  /// Single root element in a [FormatusDocument]
  body(
    'body',
    FormatusType.body,
    null,
    TextStyle(fontSize: kDefaultFontSize),
  ),

  /// Inline format to display bold text
  bold(
    'b',
    FormatusType.inline,
    Icon(Icons.format_bold),
    TextStyle(fontWeight: FontWeight.bold),
  ),

  /// Action to set color of any top-level or inline element
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

  /// TODO implement subscript
  // subscript requires a suitable icon for the formatting action
  // Example for H_2_O: TextSpan( text: 'H'),
  // WidgetSpan(child: Transform.translate(
  //  offset: Offset(2, 5), child: Text('2', style: TextStyle(fontSize: 20 )))

  /// TODO implement superscript
  // superscript requires a suitable icon for the formatting action
  // Example for x^y: TextSpan( text: 'x'),
  // WidgetSpan(child: Transform.translate(
  //  offset: Offset(2, -10), child: Text('y', style: TextStyle(fontSize: 20 )))

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

  static Formatus find(String text) => findEnum(text, Formatus.values,
      defaultValue: Formatus.text, withKey: true);
}

class FormatusAnchor {
  String href;
  String name;

  FormatusAnchor({
    this.href = '',
    this.name = '',
  });

  String toHtml() => '<href="$href">$name</a>';

  @override
  String toString() => toHtml();
}

///
/// HTML attribute names used in [Formatus]
///
enum FormatusAttribute {
  /// TextStyle.backgroundColor
  bgcolor,

  /// TextStyle.color
  color,

  /// only usable in link element
  href,
}

///
/// HTML color names used in [Formatus]
///
enum FormatusColor {
  black('000000'),
  blue('0000ff'),
  cyan('00ffff'),
  darkOrange('ff8c00'),
  gold('ffd700'),
  green('008000'),
  orange('ffa500'),
  red('ff0000'),
  white('ffffff'),
  yellow('ffff00');

  final String hexCode;

  const FormatusColor(this.hexCode);

  String toHtml() => 'color:"$name"';

  static FormatusColor find(String text) => findEnum(text, FormatusColor.values,
      defaultValue: FormatusColor.black, withKey: true);
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

  /// The single root element in [FormatusDocument]
  body,

  /// Top level elements can only contain `inline` elements
  topLevel,
}

///
/// Finds an enumeration item either by its name or by its key
///
dynamic findEnum(
  String? text,
  List<dynamic> values, {
  dynamic defaultValue,
  bool withKey = true,
}) {
  if (text != null) {
    if (withKey) {
      for (dynamic enumItem in values) {
        if (enumItem.key == text) {
          return enumItem;
        }
      }
    }
    if (!text.contains('.')) {
      String name = values[0].toString();
      name = name.substring(0, name.indexOf('.'));
      text = '$name.$text';
    }
    text = text.toLowerCase();
    for (dynamic enumItem in values) {
      if (enumItem.toString().toLowerCase() == text) {
        return enumItem;
      }
    }
  }
  return defaultValue;
}
