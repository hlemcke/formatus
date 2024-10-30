import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  FormatusNode root = FormatusNode(format: Formatus.body);
  FormatusNode paragraph = FormatusNode(format: Formatus.paragraph);
  FormatusNode bold = FormatusNode(format: Formatus.bold);
  FormatusNode italic = FormatusNode(format: Formatus.italic);
  FormatusNode textNode = FormatusNode(text: 'this is a text node');
  root.addChild(paragraph);
  paragraph.addChild(bold);
  bold.addChild(italic);
  italic.addChild(textNode);
  group('Format difference tests', () {
    test('same formats', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
        Formatus.bold
      };
      DeltaFormat difference =
          DeltaFormat(textNode: textNode, selectedFormats: selectedFormats);
      expect(difference.isEmpty, true);
    });

    ///
    test('formats added', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
        Formatus.underline,
        Formatus.bold
      };
      DeltaFormat difference =
          DeltaFormat(textNode: textNode, selectedFormats: selectedFormats);
      expect(difference.isEmpty, false);
      expect(difference.added, {Formatus.underline});
    });

    ///
    test('formats removed', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
      };
      DeltaFormat difference =
          DeltaFormat(textNode: textNode, selectedFormats: selectedFormats);
      expect(difference.isEmpty, false);
      expect(difference.removed, {Formatus.bold});
    });

    ///
    test('formats added and removed', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
        Formatus.underline,
      };
      DeltaFormat difference =
          DeltaFormat(textNode: textNode, selectedFormats: selectedFormats);
      expect(difference.isEmpty, false);
      expect(difference.added, {Formatus.underline});
      expect(difference.removed, {Formatus.bold});
    });
  });
}
