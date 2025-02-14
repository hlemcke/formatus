import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';

void main() {
  group('ParserTests', () {
    //---
    test('parse top level elements without nesting', () {
      String html = '''
<h1>Formatus Features</h1>
<p>Text with italic, bold and underlined words</p>
''';
      FormatusControllerImpl textController =
          FormatusControllerImpl(formattedText: html);
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
          FormatusController(formattedText: html);
      expect(textController.formattedText, html.replaceAll('\n', ''));
    });

    //---
    test('Parse nested formats', () {
      String html = '''
<h1>Formatus Features</h1>
<p>Text with <i>italic, <b>bold and <u>underlined</u></b> words</i></p>
''';
      FormatusController textController =
          FormatusController(formattedText: html);
      expect(textController.formattedText, html.replaceAll('\n', ''));
    });

    //---
    test('Parse tags with attributes', () {
      String html = '''
<h1>Formatus Features</h1>
<p><color orange>Orange Text with <i>italic, <b>bold and <u>underlined</u></b> words</i></color></p>
<p>Second paragraph references <a media:42>media object</a></p>
''';
      FormatusController textController =
          FormatusController(formattedText: html);
      expect(textController.formattedText, html.replaceAll('\n', ''));
    });

    //---
    test('Parse color tag and short closings', () {
      String html = '<p><color blue>Blue</> with <b>bold</> words</>';
      FormatusControllerImpl controller =
          FormatusControllerImpl(formattedText: html);
      expect(controller.document.textNodes.length, 4);
    });
  });
}
