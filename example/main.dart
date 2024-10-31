import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

/// Entry point for example application
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: const MyHomePage(),
        darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.amber,
            fontFamily: 'Roboto',
            useMaterial3: true),
        theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: Colors.amber,
            fontFamily: 'Roboto',
            useMaterial3: true),
        themeMode: ThemeMode.system,
      );
}

///
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FormatusController controller;
  final FocusNode _formatusFocus = FocusNode(debugLabel: 'formatus');
  final String htmlText = '<h1>Formatus Features</h1>'
      '<p>Text with <b>bold</b>, <i>italic</i> and <u>underlined</u> words</p>.'
      '<p>Second paragraph <i>contains <s>nested</s> and</i>'
      ' <u>under<b>line</b>d</u> formats.</p>';
  String _editedText = '';

  @override
  void initState() {
    super.initState();
    controller = FormatusController.fromHtml(initialHtml: htmlText);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text('Formatus Rich-Text-Editor'),
      );

  Widget _buildBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.deepPurpleAccent),
          FormatusBar(
            formatusController: controller,
            textFieldFocus: _formatusFocus,
          ),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              label: Text('Editable Input Field'),
            ),
            focusNode: _formatusFocus,
            minLines: 3,
            maxLines: 10,
          ),
          _buildActionDivider(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purpleAccent),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Text(_editedText),
          ),
        ],
      );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildActionDivider() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: Divider(color: Colors.deepPurpleAccent)),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: ElevatedButton(
              onPressed: () =>
                  setState(() => _editedText = controller.toHtml()),
              child: const Text('Save'),
            ),
          ),
          const Expanded(child: Divider(color: Colors.deepPurpleAccent)),
        ],
      );
}
