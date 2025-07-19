import 'package:flutter/material.dart';

import 'formatus_document.dart';

const double kDefaultFontSize = 14.0;

///
/// Formats for:
///
/// * Sections
/// * Lists
/// * Inlines
///
/// Each entry provides default values for [FormatusAction] widget
/// and display format. Some entries require an attribute.
///
enum Formatus {
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

  /// Inline format to display bold text
  bold(
    'b',
    FormatusType.inline,
    Icon(Icons.format_bold),
    TextStyle(fontWeight: FontWeight.bold),
  ),

  /// Inline format to display text in a specified color
  color('div', FormatusType.inline, Icon(Icons.format_color_text), null),
  colorDeprecated(
    'color',
    FormatusType.inline,
    Icon(Icons.unpublished_outlined),
    null,
  ),

  /// Section element header 1 (largest)
  header1(
    'h1',
    FormatusType.section,
    FormatusActionText(text: 'H1'),
    TextStyle(fontSize: kDefaultFontSize * 1.9),
  ),

  /// Section element header 2 (larger)
  header2(
    'h2',
    FormatusType.section,
    FormatusActionText(text: 'H2'),
    TextStyle(fontSize: kDefaultFontSize * 1.6),
  ),

  /// Section element header 3 (large)
  header3(
    'h3',
    FormatusType.section,
    FormatusActionText(text: 'H3'),
    TextStyle(fontSize: kDefaultFontSize * 1.3),
  ),

  /// Section element. Splits text at current cursor position
  /// and inserts a horizontal ruler
  horizontalRuler('hr', FormatusType.section, Text('-'), null),

  /// Can be used to put a small gap between format actions
  gap('?', FormatusType.bar, null, null),

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

  /// Line-breaks are automatically inserted between sections
  lineBreak('', FormatusType.section, null, null),

  /// Section element of an ordered list entry.
  /// In html this would be an `li` element of the enclosing `ol`
  orderedList('ol', FormatusType.list, Icon(Icons.format_list_numbered), null),

  /// Section element containing text and other inline elements
  paragraph(
    'p',
    FormatusType.section,
    FormatusActionText(text: 'P'),
    TextStyle(fontSize: kDefaultFontSize),
  ),

  /// Empty format used for placeholders to ensure null safety
  placeHolder('?', FormatusType.none, null, null),

  /// Single root element in a [FormatusDocument]
  ///
  /// This element can have attributes:
  /// * align = [[left, center, right]]
  /// * color from [FormatusColor)
  ///
  root('body', FormatusType.root, null, TextStyle(fontSize: kDefaultFontSize)),

  /// Inline format to strike through text
  strikeThrough(
    's',
    FormatusType.inline,
    Icon(Icons.format_strikethrough),
    TextStyle(decoration: TextDecoration.lineThrough),
  ),

  /// Inline format to make text smaller and put it a little bit below the line
  ///
  /// In markdown this would look like: `H_2_O`. In this case, digit 2 is not
  /// underlined because it is prefixed with a non-blank char.
  subscript('sub', FormatusType.inline, FormatusActionText(text: 'sub'), null),

  /// Inline format to make text smaller and put it a little bit above the line
  ///
  /// In markdown this would look like: `x^y`
  superscript(
    'super',
    FormatusType.inline,
    FormatusActionText(text: 'sup'),
    null,
  ),

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

  /// Section element of an unordered list entry.
  /// In html this would be an `li` element of the enclosing `ul`
  unorderedList(
    'ul',
    FormatusType.list,
    Icon(Icons.format_list_bulleted),
    null,
  );

  final String key;
  final FormatusType type;
  final Widget? icon;
  final TextStyle? style;

  const Formatus(this.key, this.type, this.icon, this.style);

  bool get isInline => type == FormatusType.inline;

  bool get isList => type == FormatusType.list;

  bool get isSection => type == FormatusType.section;

  /// Scale factor used for sections
  double get scaleFactor => (this == Formatus.header1)
      ? 1.9
      : (this == Formatus.header2)
      ? 1.6
      : (this == Formatus.header1)
      ? 1.3
      : 1.0; // <p>

  @override
  String toString() => '<$key>';

  static Formatus find(String text) => findEnum(
    text,
    Formatus.values,
    defaultValue: Formatus.text,
    withKey: true,
  );
}

///
/// Format action displaying given `text`.
/// `typography` defaults to normal text.
///
class FormatusActionText extends StatelessWidget {
  const FormatusActionText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => (text == 'sub')
      ? Transform.translate(
          offset: Offset(0, 4),
          child: Text(text, textScaler: TextScaler.linear(0.7)),
        )
      : (text == 'sup')
      ? Transform.translate(
          offset: Offset(0, -4),
          child: Text(text, textScaler: TextScaler.linear(0.7)),
        )
      : Text(
          text,
          style: TextStyle(
            fontSize: kDefaultFontSize * 1.2,
            fontWeight: FontWeight.bold,
          ),
        );
}

///
///
///
class FormatusAnchor {
  String href;
  String name;

  FormatusAnchor({this.href = '', this.name = ''});

  String toHtml() => '<href="$href">$name</a>';

  @override
  String toString() => toHtml();
}

///
/// HTML colors used in [Formatus].
/// Values are official HTML colors.
///
/// Colors are ordered by their occurrence in a rainbow.
///
/// **DO NOT CHANGE ORDER**
///
List<Color> formatusColors = [
  Colors.transparent, // to remove a color
  Color(0xFFff0000), // red
  Color(0xFF800000), // maroon
  Color(0xFF808000), // olive
  Color(0xFFffa500), // orange
  Color(0xFFffd700), // gold
  Color(0xFFffff00), // yellow
  Color(0xFF008080), // teal
  Colors.green, // green 0xFF008000,
  Color(0xFF00ff00), // lime
  Color(0xFFff00ff), // magenta
  Color(0xFFda70d6), // orchid
  Color(0xFF800080), // purple
  Color(0xFF00ffff), // aqua
  Colors.blue, // blue
  Color(0xFF000080), // navy
  Color(0xFFffffff), // white
  Color(0xFFC0C0C0), // silver
  Color(0xFF808080), // grey
  Colors.black, // black
];

Color colorFromHex(String hex) {
  hex = hex.startsWith('#') ? hex.substring(1) : hex;
  hex = hex.startsWith('0x') ? hex.substring(2) : hex;
  return Color(int.parse(hex, radix: 16));
}

String hexFromColor(Color color) {
  String a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
  String r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  String g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  String b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '$a$r$g$b';
}

///
/// Type of a [Formatus] action / style
///
enum FormatusType {
  /// Flutter supports alignment only for the whole text.
  /// Therefor any action with this type will be applied as an attribute
  /// to the outer \<body> element.
  alignment,

  /// Used for bar-actions like a gap which do not apply any format to the text
  bar,

  /// Inline elements can be nested
  inline,

  /// (Un)ordered list is child of _paragraph_. May contain 'inline' elements.
  list,

  /// No action or type at all
  none,

  /// The single root element in [FormatusDocument]
  root,

  /// Section elements can only contain `inline` elements
  section,
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
