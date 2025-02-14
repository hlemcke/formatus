import 'package:flutter/cupertino.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_tree.dart';

class FormatusViewer extends StatelessWidget {
  late final FormatusDocument doc;

  FormatusViewer({
    super.key,
    required String formattedText,
  }) {
    doc = FormatusDocument(body: formattedText);
  }

  @override
  Widget build(BuildContext context) =>
      RichText(text: FormatusTree.buildFormattedText(doc.root.children));
}
