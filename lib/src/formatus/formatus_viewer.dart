import 'package:flutter/cupertino.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

class FormatusViewer extends StatelessWidget {
  late final FormatusDocument doc;

  FormatusViewer({
    super.key,
    required String formattedText,
  }) {
    doc = FormatusDocument(formatted: formattedText);
  }

  @override
  Widget build(BuildContext context) => RichText(text: doc.results.textSpan);
}
