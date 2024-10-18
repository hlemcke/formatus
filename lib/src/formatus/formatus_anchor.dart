import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

///
/// Resembles an html anchor element
///
/// ```
/// <a href="$url">$name</a>
/// ```
class FormatusAnchor {
  String name;
  String url;

  FormatusAnchor({
    this.name = '',
    this.url = '',
  });

  bool get isEmpty => name.isEmpty || url.isEmpty;

  String toHtml() => '<a href="$url">$name</a>';

  @override
  String toString() => '$name -> $url';
}

Future<FormatusAnchor?> showFormatusAnchorDialog(
    BuildContext context, FormatusController controller) {
  // TODO extract anchor element from current cursor position or create new
  FormatusAnchor element = FormatusAnchor();
  return showDialog(
      context: context,
      builder: (BuildContext context) => FormatusLinkDialog(anchor: element));
}

///
/// Manages html anchor element
///
/// TODO requires function parameter to select media
/// TODO requires function parameter to build link and name from selected media
class FormatusLinkDialog extends StatefulWidget {
  FormatusAnchor anchor;

  ///
  /// `controller` is required to:
  ///
  /// * determine cursor position
  /// * insert new anchor element or update current one
  ///
  FormatusLinkDialog({
    required this.anchor,
  });

  @override
  State<StatefulWidget> createState() => _FormatusLinkDialogState();
}

class _FormatusLinkDialogState extends State<FormatusLinkDialog> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // TODO fetch anchor element at cursor position and set name and url from it
  }

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            IconButton(
              icon: Icon(Icons.commit),
              onPressed: () => _onCommit(),
            ),
          ],
        ),
        children: [
          Text('button to select media from local file system'),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextFormField(
            controller: _urlController,
            decoration: InputDecoration(labelText: 'URL'),
          ),
        ],
      );

  /// * no URL -> delete anchor element if inside one. Else just close
  /// * cursor outside an anchor element -> insert new one at cursor position
  /// * cursor inside anchor element -> update element
  void _onCommit() {
    FormatusAnchor anchor =
        FormatusAnchor(name: _nameController.text, url: _urlController.text);
    Navigator.of(context).pop(anchor.isEmpty ? null : anchor);
  }
}
