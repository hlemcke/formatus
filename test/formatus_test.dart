import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';

void main() {
  group('Parser tests', () {
    //---
    test('parse top level elements without nesting', () {
      String html = '''
<h1>Formatus Features</h1>
<p>Text with italic, bold and underlined words</p>
''';
      FormatusController textController =
          FormatusController.fromHtml(initialHtml: html);
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
          FormatusController.fromHtml(initialHtml: html);
      expect(textController.toHtml(), html.replaceAll('\n', ''));
    });

    //---
    test('Parse nested formats', () {
      String html = '''
<h1>Formatus Features</h1>
<p>Text with <i>italic, <b>bold and <u>underlined</u></b> words</i></p>
''';
      FormatusController textController =
          FormatusController.fromHtml(initialHtml: html);
      expect(textController.toHtml(), html.replaceAll('\n', ''));
    });
  });
}
