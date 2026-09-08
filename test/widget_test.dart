import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

import 'test_helper.dart';

void main() {
  final Color yellow = Color(0xFFffeb3b);
  final String yellowDiv = '<div style="color: #ffeb3bff;">';

  testWidgets('Make "sunny" yellow', (WidgetTester tester) async {
    //--- given
    final String input = '<h1>Title</h1><p>A sunny day</p>';
    String formatted = '';
    FormatusControllerImpl controller = FormatusControllerImpl(
      formattedText: input,
      onChanged: (f) => formatted = f,
    );
    expect(controller.formattedText, input);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: controller)),
      ),
    );

    //--- when
    controller.selection = TextSelection(baseOffset: 8, extentOffset: 13);
    controller.selectedColor = Colors.yellow;
    controller.updateInlineFormat(Formatus.color, true);

    //--- then
    FormatusDocument doc = controller.document;
    TreeHelper.printAll(doc, 'with yellow');
    expect(doc.childCount, 2);
    expect(doc[0].tag, Formatus.header1);
    expect(doc[1].tag, Formatus.paragraph);
    expect(formatted, '<h1>Title</h1><p>A ${yellowDiv}sunny</div> day</p>');
    expect(doc.results.plainText, 'Title\nA sunny day');
    expect(doc[1][1].tag, Formatus.color);
    expect(doc[1][1][0].tag, Formatus.text);
    expect(doc[1][1][0].text, 'sunny');
    expect(doc[1][1][0].findColor.toARGB32(), yellow.toARGB32());
  });
}
