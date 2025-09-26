import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';

void main() {
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
    controller.updateInlineFormat(Formatus.color);

    //--- then
    expect(controller.document.textNodes.length, 5);
    expect(
      formatted,
      '<h1>Title</h1><p>A '
      '<div style="color: #${Colors.yellow.toARGB32().toRadixString(16)};">'
      'sunny</div> day</p>',
    );
  });
}
