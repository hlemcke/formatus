import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';

void main() {
  group('ParserTests', () {
    //---
    test('parse top level elements without nesting', () {
      String html = '''
<h1>Formatus Features</h1>
<p>Text with italic, bold and underlined words</p>
''';
      FormatusController textController =
          FormatusController.fromFormattedText(formattedText: html);
      expect(textController.text,
          'Formatus Features\nText with italic, bold and underlined words');
    });

    //---
    test('Parse single nested elements', () {
      String html = '''
<h1>Formatus Features</h1>
<p>Text with <i>italic</i>, <b>bold</b> and <u>underlined</u> words</p>
''';
      FormatusController textController =
          FormatusController.fromFormattedText(formattedText: html);
      expect(textController.formattedText, html.replaceAll('\n', ''));
    });

    //---
    test('Parse nested formats', () {
      String html = '''
<h1>Formatus Features</h1>
<p>Text with <i>italic, <b>bold and <u>underlined</u></b> words</i></p>
''';
      FormatusController textController =
          FormatusController.fromFormattedText(formattedText: html);
      expect(textController.formattedText, html.replaceAll('\n', ''));
    });

    //---
    test('Parse tags with attributes', () {
      String html = '''
<h1>Formatus Features</h1>
<p color="orange">Orange Text with <i>italic, <b>bold and <u>underlined</u></b> words</i></p>
<p>Second paragraph references <a href="media:42">media object</a></p>
''';
      FormatusController textController =
          FormatusController.fromFormattedText(formattedText: html);
      expect(textController.formattedText, html.replaceAll('\n', ''));
    });
  });
}
