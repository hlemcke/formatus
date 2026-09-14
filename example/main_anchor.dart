import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';
import 'package:url_launcher/url_launcher.dart';

///
/// Demonstrates `FormatusViewer.onRenderAnchor`: an anchor rendered by
/// [FormatusViewer] becomes a real, clickable link that opens the browser -
/// without `formatus` itself depending on `url_launcher`. This example app
/// pulls in `url_launcher` on its own (see `dev_dependencies` in the
/// package's `pubspec.yaml`) and passes a renderer that uses it.
///
void main() {
  runApp(const MyApp());
}

const String htmlText =
    '<p>Link to <a href="https://www.djarjo.com">Djarjo</a> homepage</p>';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: const AnchorExamplePage());
}

class AnchorExamplePage extends StatelessWidget {
  const AnchorExamplePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Formatus - clickable anchor')),
    body: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: FormatusViewer(
        formattedText: htmlText,
        onRenderAnchor: (context, anchor) => _buildLinkSpan(context, anchor),
      ),
    ),
  );

  /// Renders [anchor] as an underlined, hand-cursor, clickable span which
  /// opens `anchor.href` via `url_launcher`.
  InlineSpan _buildLinkSpan(BuildContext context, FormatusAnchor anchor) =>
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openUrl(context, anchor.href),
            child: Text(
              anchor.name,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      );

  Future<void> _openUrl(BuildContext context, String href) async {
    final Uri? uri = Uri.tryParse(href);
    final bool opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $href')));
    }
  }
}
