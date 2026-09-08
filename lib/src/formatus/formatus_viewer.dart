import 'package:flutter/material.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

class FormatusViewer extends StatelessWidget {
  late final FormatusDocument doc;

  FormatusViewer._();

  FormatusViewer({super.key, required String formattedText}) {
    doc = FormatusDocument(formatted: formattedText);
  }

  factory FormatusViewer.fromDocument({
    dynamic key,
    required FormatusDocument doc,
  }) {
    FormatusViewer viewer = FormatusViewer._();
    viewer.doc = doc;
    return viewer;
  }

  @override
  Widget build(BuildContext context) =>
      SelectableText.rich(doc.results.textSpan4Viewer, showCursor: true);
}
