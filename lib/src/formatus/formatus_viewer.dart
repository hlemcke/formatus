import 'package:flutter/material.dart';

import '../../formatus.dart';

class FormatusViewer extends StatelessWidget {
  final FormatusController controller;
  final bool isFromController;

  const FormatusViewer._({
    required this.controller,
    required this.isFromController,
  });

  ///
  /// Viewer displays static content.
  ///
  /// `formattedText` must be a HTML string with a list of section tags.
  /// Each section tag may contain plain text which can be nested into
  /// formatting inline tags.
  ///
  /// Example:
  /// ``` HTML
  /// <h1>Title</h1><p>Paragraph with <b>bold <u>underlined</u></b> words</p>
  /// <p><ol><li>List item</li><li><i>second</i> item</li></ol></p>
  /// ```
  ///
  factory FormatusViewer({Key? key, required String formattedText}) =>
      FormatusViewer._(
        controller: FormatusController(formattedText: formattedText),
        isFromController: false,
      );

  ///
  /// Viewer displays content from [FormatusController].
  /// Gets automatically updated whenever controller text changes.
  ///
  factory FormatusViewer.fromController({
    Key? key,
    required FormatusController controller,
  }) => FormatusViewer._(controller: controller, isFromController: true);

  @override
  Widget build(BuildContext context) => isFromController
      ? ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              SelectableText.rich(controller.textSpan4Viewer, showCursor: true),
        )
      : SelectableText.rich(controller.textSpan4Viewer, showCursor: true);
}
