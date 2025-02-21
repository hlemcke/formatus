import 'package:flutter/material.dart';

import 'formatus_document.dart';

const double kDefaultFontSize = 14.0;

///
/// Formats for:
/// * Sections
/// * Inlines
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

  /// Inline format to display bold text
  bold(
    'b',
    FormatusType.inline,
    Icon(Icons.format_bold),
    TextStyle(fontWeight: FontWeight.bold),
  ),

  /// Inline format to display text in a specified color
  color(
    'color',
    FormatusType.inline,
    Icon(Icons.format_color_text),
    null,
  ),

  /// Section element header 1 (largest)
  header1(
    'h1',
    FormatusType.section,
    FormatusActionText(text: 'H1'),
    TextStyle(fontSize: kDefaultFontSize * 2.0, height: 2.0),
  ),

  /// Section element header 2 (larger)
  header2('h2', FormatusType.section, FormatusActionText(text: 'H2'),
      TextStyle(fontSize: kDefaultFontSize * 1.7)),

  /// Section element header 3 (large)
  header3('h3', FormatusType.section, FormatusActionText(text: 'H3'),
      TextStyle(fontSize: kDefaultFontSize * 1.4)),

  /// Section element. Splits text at current cursor position
  /// and inserts a horizontal ruler
  horizontalRuler(
    'hr',
    FormatusType.section,
    Text('-'),
    null,
  ),

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
  orderedList(
    'ol',
    FormatusType.section,
    Icon(Icons.format_list_numbered),
    null,
  ),

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
  root(
    'body',
    FormatusType.root,
    null,
    TextStyle(fontSize: kDefaultFontSize),
  ),

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
  subscript(
    'sub',
    FormatusType.inline,
    FormatusActionText(text: 'sub', typography: FormatusTypography.subscript),
    null,
  ),

  /// Inline format to make text smaller and put it a little bit above the line
  ///
  /// In markdown this would look like: `x^y`
  superscript(
    'super',
    FormatusType.inline,
    FormatusActionText(text: 'sup', typography: FormatusTypography.superscript),
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
    FormatusType.section,
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

  bool get isInline => type == FormatusType.inline;

  bool get isSection => type == FormatusType.section;

  @override
  String toString() => '<$key>';

  static Formatus find(String text) => findEnum(text, Formatus.values,
      defaultValue: Formatus.text, withKey: true);
}

///
/// Format action displaying given `text`.
/// `typography` defaults to normal text.
///
class FormatusActionText extends StatelessWidget {
  const FormatusActionText({
    super.key,
    required this.text,
    this.typography = FormatusTypography.normal,
  });

  final String text;
  final FormatusTypography typography;

  @override
  Widget build(BuildContext context) =>
      (typography == FormatusTypography.normal)
          ? Text(
              text,
              style: TextStyle(
                fontSize: kDefaultFontSize * 1.2,
                fontWeight: FontWeight.bold,
              ),
            )
          : Transform.translate(
              offset: Offset(
                  0, (typography == FormatusTypography.subscript) ? 4 : -4),
              child: Text(text, textScaler: TextScaler.linear(0.7)),
            );
}

///
///
///
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
/// HTML color names used in [Formatus]
///
enum FormatusColor {
  aqua('0xFF00FFFF'),
  black('0xFF000000'),
  blue('0xFF0000ff'),
  fuchsia('0xFFFF00FF'),
  grey('0xFF808080'),
  green('0xFF008000'),
  lime('0xFF00FF00'),
  maroon('0xFF800000'),
  navy('0xFF000080'),
  olive('0xFF808000'),
  orange('0xFFFFa500'),
  purple('0xFF800080'),
  red('0xFFFF0000'),
  silver('0xFFC0C0C0'),
  teal('0xFF008080'),
  white('0xFFFFFFFF'),
  yellow('0xFFFFFF00');

  final String key;

  const FormatusColor(this.key);

  String toHtml() => 'color:"$name"';

  static FormatusColor find(String text) => findEnum(text, FormatusColor.values,
      defaultValue: FormatusColor.black, withKey: true);
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

///
/// Typography values
///
enum FormatusTypography { normal, subscript, superscript }
