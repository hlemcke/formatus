import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';

void main() {
  test('Render and display example text', () {
    String html = '''
<h1>Formatus Features</h1>
<p>Text with <i>italic</i>, <b>bold</b> and <u>underlined</u> words</p>
''';
    FormatusController textController =
        FormatusController.fromHtml(initialHtml: html);
    TextFormField(
      controller: textController,
    );
    expect(textController.text,
        'Formatus Features\nText with italic, bold and underlined words');
  });
}
