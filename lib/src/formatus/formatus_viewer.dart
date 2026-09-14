import 'package:flutter/material.dart';

import '../../formatus.dart';

/// Signature for callback `onRenderAnchor`.
///
/// Invoked once per anchor element found in the viewed text. Return an
/// [InlineSpan] to be displayed in place of the anchor's plain text.
/// If not supplied, or if it returns `null`, the anchor is rendered as
/// plain, non-interactive text.
typedef AnchorRenderer =
    InlineSpan? Function(BuildContext context, FormatusAnchor anchor);

///
/// Marker span produced by [FormatusResults] for an anchor element.
/// Carries the [FormatusAnchor] so [FormatusViewer] can give it to
/// [AnchorRenderer] at build time.
///
class FormatusAnchorSpan extends TextSpan {
  final FormatusAnchor anchor;

  const FormatusAnchorSpan({
    required this.anchor,
    required super.text,
    super.style,
  });
}

///
///
///
class FormatusViewer extends StatelessWidget {
  final AnchorRenderer? onRenderAnchor;
  final FormatusController controller;
  final bool isFromController;
  final bool selectable;

  const FormatusViewer._({
    required this.controller,
    required this.isFromController,
    this.onRenderAnchor,
    this.selectable = false,
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
  factory FormatusViewer({
    Key? key,
    required String formattedText,
    AnchorRenderer? onRenderAnchor,
    bool selectable = false,
  }) => FormatusViewer._(
    controller: FormatusController(formattedText: formattedText),
    isFromController: false,
    onRenderAnchor: onRenderAnchor,
    selectable: selectable,
  );

  ///
  /// Viewer displays content from [FormatusController].
  /// Gets automatically updated whenever controller text changes.
  ///
  factory FormatusViewer.fromController({
    Key? key,
    required FormatusController controller,
    AnchorRenderer? onRenderAnchor,
    bool selectable = false,
  }) => FormatusViewer._(
    controller: controller,
    isFromController: true,
    onRenderAnchor: onRenderAnchor,
    selectable: selectable,
  );

  @override
  Widget build(BuildContext context) => isFromController
      ? ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _buildRichText(context),
        )
      : _buildRichText(context);

  Widget _buildRichText(BuildContext context) {
    final TextSpan span = _buildRootSpan(context);
    return selectable
        ? SelectableText.rich(span, showCursor: true)
        : Text.rich(span);
  }

  /// Returns `controller.textSpan4Viewer` unchanged when no
  /// `onRenderAnchor` callback was supplied - otherwise rewrites the tree,
  /// handing every [FormatusAnchorSpan] to the callback.
  TextSpan _buildRootSpan(BuildContext context) {
    final renderer = onRenderAnchor;
    final TextSpan root = controller.textSpan4Viewer;
    if (renderer == null) return root;
    return _rewrite(context, root, renderer) as TextSpan;
  }

  InlineSpan _rewrite(
    BuildContext context,
    InlineSpan span,
    AnchorRenderer renderer,
  ) {
    if (span is FormatusAnchorSpan) {
      return renderer(context, span.anchor) ?? span;
    }
    if (span is TextSpan) {
      final children = span.children;
      if (children == null || children.isEmpty) return span;
      return TextSpan(
        text: span.text,
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
        children: [
          for (final child in children) _rewrite(context, child, renderer),
        ],
      );
    }
    //--- e.g. WidgetSpan: nothing inside it to rewrite
    return span;
  }
}
