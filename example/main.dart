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

/// TODO frame input field
/// TODO add dropdown: empty, short, long
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
  String _formattedText = '';

  @override
  void initState() {
    super.initState();
    controller = FormatusController.fromFormattedText(
        formattedText: textTemplates[initialTemplateKey] ?? '');
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
          ),
          _buildActionDivider(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purpleAccent),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Text(_formattedText),
          ),
          // const Divider(color: Colors.deepPurpleAccent),
          // TextField(
          //   buildCounter: (BuildContext context,
          //           {required int currentLength,
          //           required int? maxLength,
          //           required bool isFocused}) =>
          //       _buildCounter(currentLength, isFocused, controller.selection),
          //   decoration: const InputDecoration(
          //       border: OutlineInputBorder(), labelText: 'Test Input'),
          // ),
        ],
      );

  Widget _buildActionDivider() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: Divider(color: Colors.deepPurpleAccent)),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: ElevatedButton(
              onPressed: () =>
                  setState(() => _formattedText = controller.formattedText),
              child: const Text('Save'),
            ),
          ),
          const Expanded(child: Divider(color: Colors.deepPurpleAccent)),
        ],
      );

  Widget _buildCounter(
          int currentLength, bool isFocused, TextSelection selection) =>
      Text('${selection.start}..${selection.end} of $currentLength'
          ' ${isFocused ? "focused" : ""}');

  Widget _buildTextPreselection() => DropdownMenu<String>(
        dropdownMenuEntries: [
          for (String key in textTemplates.keys)
            DropdownMenuEntry<String>(label: key, value: key),
        ],
        initialSelection: initialTemplateKey,
        label: const Text('Preselect text'),
        onSelected: (key) =>
            setState(() => controller.formattedText = textTemplates[key]!),
      );
}
