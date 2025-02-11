import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

/// Entry point of example application
void main() {
  runApp(const MyApp());
}

const String initialTemplateKey = 'Long';
const Map<String, String> textTemplates = {
  'Empty': '',
  'Short': '<p color="blue">Blue with <b>bold</b> words</p>',
  initialTemplateKey: '''
<h1>Formatus Features</h1>
<h2>Text with <b>bold</b>, <i>italic</i> and <u>underlined</u> words</h2>.
<p>Third <i>contains <s>nested</s> and</i> <u>under<b>line</b>d</u> text.</p>
''',
};

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
  String savedText = '';

  @override
  void initState() {
    super.initState();
    controller = FormatusController(
        formattedText: textTemplates[initialTemplateKey] ?? '',
        onChanged: (v) => setState(() {
              debugPrint('controller changed to: "$v"');
              savedText = v;
            }));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text('Formatus Rich-Text-Editor'),
        actions: [
          _buildTextPreselection(),
        ],
      );

  Widget _buildBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.deepPurpleAccent),
          FormatusBar(
            controller: controller,
            textFieldFocus: _formatusFocus,
          ),
          TextFormField(
            buildCounter: (BuildContext context,
                    {required int currentLength,
                    required int? maxLength,
                    required bool isFocused}) =>
                _buildCounter(currentLength, isFocused, controller.selection),
            controller: controller,
            decoration:
                const InputDecoration(focusedBorder: OutlineInputBorder()),
            focusNode: _formatusFocus,
            minLines: 3,
            maxLines: 10,
            onChanged: (_) => setState(() => ()),
            showCursor: true,
          ),
          const Divider(color: Colors.deepPurpleAccent),
          SizedBox(height: 16),
          _buildSavedText(),
          SizedBox(height: 16),
          _buildFormatusViewer(),
        ],
      );

  Widget _buildCounter(
          int currentLength, bool isFocused, TextSelection selection) =>
      Text('${selection.start}..${selection.end} of $currentLength'
          ' ${isFocused ? "focused" : ""}');

  Widget _buildFormatusViewer() => Frame(
        label: 'FormatusViewer',
        child: FormatusViewer(formattedText: controller.formattedText),
      );

  Widget _buildSavedText() => Frame(
        label: 'Formatted Text',
        child: Text(controller.formattedText),
      );

  Widget _buildTextPreselection() => DropdownMenu<String>(
        dropdownMenuEntries: [
          for (String key in textTemplates.keys)
            DropdownMenuEntry<String>(label: key, value: key),
        ],
        initialSelection: initialTemplateKey,
        label: const Text('Preselect text'),
        onSelected: (key) {
          _formatusFocus.requestFocus();
          setState(() => controller.formattedText = textTemplates[key]!);
        },
      );
}

///
/// Frame with label
///
class Frame extends StatelessWidget {
  final Widget child;
  final String label;

  const Frame({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          labelText: label,
        ),
        child: child,
      );
}
