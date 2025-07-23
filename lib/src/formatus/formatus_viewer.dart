import 'package:flutter/material.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

class FormatusViewer extends StatelessWidget {
  late final FormatusDocument doc;

  FormatusViewer({super.key, required String formattedText}) {
    doc = FormatusDocument(formatted: formattedText, forViewer: true);
  }

  @override
  Widget build(BuildContext context) =>
      SelectableText.rich(doc.results.textSpan, showCursor: true);
}
