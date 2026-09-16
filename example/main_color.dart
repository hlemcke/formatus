import 'package:colorus/colorus.dart';
import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

///
/// Demonstrates `FormatusBar.onSelectColor` by using the `colorus` package
/// (https://pub.dev/packages/colorus) as a fully custom color picker.
///
/// The dialog lets the user switch between every chooser variant that
/// `colorus` provides:
///  * [ColorusGrid]      - fixed rainbow palette
///  * [ColorusHueSlider]  - hue + opacity sliders
///  * [ColorusRGBSlider]  - red / green / blue (+ alpha) sliders
///  * [ColorusRing]       - ring shaped hue/saturation/value chooser
///  * [ColorusWheel]      - wheel shaped hue/saturation/value chooser
///
/// `colorus` is not a dependency of `formatus` itself. To run this example
/// add it to `dev_dependencies` in `pubspec.yaml`:
/// ```yaml
/// dev_dependencies:
///   colorus: ^1.2.1
/// ```
///
void main() {
  runApp(const MyApp());
}

const String htmlText =
    '<p><div style="color: #ff5722ff;">This</div> '
    '<div style="color: #ffe622ff;">is</div> '
    '<div style="color: #22ff40ff;">colored</div> '
    '<div style="color: #2229ffff;">text</div></p>';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: const ColorExamplePage());
}

class ColorExamplePage extends StatefulWidget {
  const ColorExamplePage({super.key});

  @override
  State<ColorExamplePage> createState() => _ColorExamplePageState();
}

class _ColorExamplePageState extends State<ColorExamplePage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'formatus');
  late final FormatusController _ctrl;
  String output = '';

  @override
  void initState() {
    super.initState();
    _ctrl = FormatusController(
      formattedText: htmlText,
      onChanged: (v) => setState(() => output = v),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Formatus - color chooser')),
    body: SafeArea(minimum: const EdgeInsets.all(16), child: _buildBody()),
  );

  Widget _buildBody() => Column(
    crossAxisAlignment: .start,
    mainAxisAlignment: .start,
    mainAxisSize: .min,
    children: [
      const Text('Use color action in format bar'),
      const SizedBox(height: 8),
      _buildBar(),
      _buildEditor(),
      const Divider(color: Colors.deepPurpleAccent, height: 24),
      SelectableText(output),
    ],
  );

  Widget _buildBar() => IntrinsicWidth(
    child: FormatusBar(
      controller: _ctrl,
      onSelectColor: (context, color) => _showColorChooser(context, color),
      textFieldFocus: _focusNode,
    ),
  );

  Widget _buildEditor() => TextFormField(
    controller: _ctrl,
    decoration: const InputDecoration(fillColor: Colors.white, filled: true),
    focusNode: _focusNode,
    minLines: 3,
    maxLines: 7,
  );

  ///
  /// Opens a dialog which lets the user pick a color with any of the
  /// `colorus` chooser widgets.
  ///
  /// Returning `null` leaves the current color unchanged (or removes it
  /// if none was set before), returning a [Color] applies it - this is
  /// exactly the contract expected by `FormatusBar.onSelectColor`.
  ///
  Future<Color?> _showColorChooser(BuildContext context, Color color) =>
      showAdaptiveDialog<Color?>(
        context: context,
        builder: (BuildContext context) =>
            _ColorusChooserDialog(initialColor: color),
      );
}

/// All chooser widgets provided by package `colorus`
enum _ColorusVariant { grid, hue, rgb, ring, wheel }

///
/// Dialog which lets the user switch between all `colorus` chooser variants
/// and finally confirms or cancels the selected color.
///
class _ColorusChooserDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorusChooserDialog({required this.initialColor});

  @override
  State<_ColorusChooserDialog> createState() => _ColorusChooserDialogState();
}

class _ColorusChooserDialogState extends State<_ColorusChooserDialog> {
  late Color _color;
  _ColorusVariant _variant = .grid;

  //--- extra options used by `ColorusRing` and `ColorusWheel`
  ColorusSliderPosition _alphaPosition = .none;
  ColorusTogglePosition _togglePosition = .none;
  bool _showValue = true;
  bool _isBlackMode = false;

  //--- extra options used by `ColorusRGBSlider`
  bool _showValues = true;
  bool _withAlpha = true;

  @override
  void initState() {
    super.initState();
    // colorus has no notion of "no color yet" -> start from an opaque color
    _color = (widget.initialColor.a == 0)
        ? Colors.deepOrange
        : widget.initialColor;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose a color'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          _buildPreview(),
          const SizedBox(height: 16),
          _buildVariantSelector(),
          const SizedBox(height: 16),
          _buildOptions(),
          _buildChooser(),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_color),
        child: const Text('Apply'),
      ),
    ],
  );

  Widget _buildPreview() => Row(
    children: [
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: _color,
        ),
        height: 32,
        width: 32,
      ),
      const SizedBox(width: 12),
      Text('#${_color.toARGB32().toRadixString(16).padLeft(8, '0')}'),
    ],
  );

  Widget _buildVariantSelector() => SegmentedButton<_ColorusVariant>(
    onSelectionChanged: (selection) =>
        setState(() => _variant = selection.first),
    segments: const [
      ButtonSegment(
        icon: Icon(Icons.grid_4x4_outlined),
        label: Text('Grid'),
        value: .grid,
      ),
      ButtonSegment(
        icon: Icon(Icons.color_lens_outlined),
        label: Text('Hue'),
        value: .hue,
      ),
      ButtonSegment(
        icon: Icon(Icons.tune_outlined),
        label: Text('RGB'),
        value: .rgb,
      ),
      ButtonSegment(
        icon: Icon(Icons.donut_large_outlined),
        label: Text('Ring'),
        value: .ring,
      ),
      ButtonSegment(
        icon: Icon(Icons.gradient_outlined),
        label: Text('Wheel'),
        value: .wheel,
      ),
    ],
    selected: {_variant},
    showSelectedIcon: false,
  );

  /// Extra controls that are only relevant for the currently selected
  /// chooser variant - mirrors the options offered by `colorus`'s own
  /// example app.
  Widget _buildOptions() {
    switch (_variant) {
      case _ColorusVariant.ring:
      case _ColorusVariant.wheel:
        return Wrap(
          crossAxisAlignment: .center,
          runSpacing: 8,
          spacing: 16,
          children: [
            DropdownMenu<ColorusSliderPosition>(
              dropdownMenuEntries: [
                for (final pos in ColorusSliderPosition.values)
                  DropdownMenuEntry(value: pos, label: pos.name),
              ],
              initialSelection: _alphaPosition,
              label: const Text('Alpha position'),
              onSelected: (v) => setState(() => _alphaPosition = v!),
            ),
            if (_variant == .wheel)
              DropdownMenu<ColorusTogglePosition>(
                dropdownMenuEntries: [
                  for (final pos in ColorusTogglePosition.values)
                    DropdownMenuEntry(value: pos, label: pos.name),
                ],
                initialSelection: _togglePosition,
                label: const Text('Toggle position'),
                onSelected: (v) => setState(() => _togglePosition = v!),
              ),
            FilterChip(
              label: const Text('Show value'),
              onSelected: (v) => setState(() => _showValue = v),
              selected: _showValue,
            ),
            if (_variant == .wheel)
              FilterChip(
                label: const Text('Black mode'),
                onSelected: (v) => setState(() => _isBlackMode = v),
                selected: _isBlackMode,
              ),
          ],
        );
      case _ColorusVariant.rgb:
        return Wrap(
          spacing: 16,
          children: [
            FilterChip(
              label: const Text('Show values'),
              onSelected: (v) => setState(() => _showValues = v),
              selected: _showValues,
            ),
            FilterChip(
              label: const Text('With alpha'),
              onSelected: (v) => setState(() => _withAlpha = v),
              selected: _withAlpha,
            ),
          ],
        );
      case _ColorusVariant.grid:
      case _ColorusVariant.hue:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChooser() {
    switch (_variant) {
      case _ColorusVariant.grid:
        return ColorusGrid(
          color: _color,
          onChanged: (col) => setState(() => _color = col),
        );
      case _ColorusVariant.hue:
        return ColorusHueSlider(
          color: _color,
          onChanged: (col) => setState(() => _color = col),
        );
      case _ColorusVariant.rgb:
        return ColorusRGBSlider(
          color: _color,
          onChanged: (col) => setState(() => _color = col),
          showValues: _showValues,
          withAlpha: _withAlpha,
        );
      case _ColorusVariant.ring:
        return SizedBox(
          height: 220,
          width: 260,
          child: ColorusRing(
            alphaPosition: _alphaPosition,
            color: _color,
            onChanged: (col) => setState(() => _color = col),
            showValue: _showValue,
          ),
        );
      case _ColorusVariant.wheel:
        return SizedBox(
          height: 260,
          width: 260,
          child: ColorusWheel(
            alphaPosition: _alphaPosition,
            color: _color,
            isBlackMode: _isBlackMode,
            onChanged: (col) => setState(() => _color = col),
            showValue: _showValue,
            togglePosition: _togglePosition,
          ),
        );
    }
  }
}
