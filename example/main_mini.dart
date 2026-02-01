import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(home: const MyHomePage());
}

///
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FocusNode _textFieldFocus = FocusNode(debugLabel: 'formatus');
  late FormatusController controller;
  bool condenseActions = false;
  String savedText = '';

  @override
  void initState() {
    super.initState();
    controller = FormatusController(
      onChanged: (v) => setState(() => savedText = v),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    debugPrint("Hot Reload triggered!");
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Formatus Rich-Text-Editor')),
    body: SafeArea(minimum: const EdgeInsets.all(16), child: _buildBody()),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildBody() => Column(
    crossAxisAlignment: .start,
    mainAxisAlignment: .start,
    children: [
      _buildFormatusEditor(),
      const Divider(color: Colors.deepPurpleAccent, height: 24),
      _buildFormatusViewer(),
    ],
  );

  Widget _buildFormatusEditor() => Frame(
    label: 'Some Rich Text',
    child: Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        FormatusBar(
          controller: controller,
          hideInactive: true,
          textFieldFocus: _textFieldFocus,
        ),
        TextFormField(
          controller: controller,
          focusNode: _textFieldFocus,
          minLines: 3,
          maxLines: 7,
        ),
      ],
    ),
  );

  Widget _buildFormatusViewer() => Frame(
    label: 'FormatusViewer',
    child: SingleChildScrollView(
      child: SizedBox(
        height: 150,
        child: FormatusViewer(formattedText: controller.formattedText),
      ),
    ),
  );
}

///
/// Frame with label
///
class Frame extends StatelessWidget {
  final Widget child;
  final String label;

  const Frame({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      labelText: label,
    ),
    child: child,
  );
}
