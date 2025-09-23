import 'package:flutter/material.dart';

import '../../formatus.dart';
import 'formatus_controller_impl.dart';
import 'formatus_document.dart';

///
/// [FormatusController] displays the tree-like structure of a
/// [FormatusDocument] into [TextSpan] to be displayed in a [TextFormField].
///
abstract class FormatusController extends TextEditingController {
  ///
  /// Creates a controller for [TextField] or [TextFormField].
  ///
  factory FormatusController({
    String? formattedText,
    ValueChanged<String>? onChanged,
    List<FormatusImage> images = const [],
  }) => FormatusControllerImpl(
    formattedText: formattedText,
    onChanged: onChanged,
    images: images,
  );

  /// Returns current text as a html formatted string
  String get formattedText;

  /// Replaces current text with the parsed `html`
  set formattedText(String html);
}
