///
/// Single change of a VITE document
///
class ViteChange {
  ViteChangeAction action = ViteChangeAction.unknown;
  int bodyIndex = -1;
  int newLength = -1;
  String removedText = '';

  ViteChange({
    required this.action,
  });

  @override
  String toString() => '${action.key} $bodyIndex "$removedText"';
}

///
/// Action of change
///
enum ViteChangeAction {
  delete('D'),
  insert('I'),
  replace('R'),
  unknown('?');

  final String key;

  const ViteChangeAction(this.key);
}

///
/// Supported document types
///
enum ViteDocType {
  html,
  json,
  markdown,
  plain,
  xml;
}

///
/// Plain text document with undo / redo functionality.
///
/// Specific types of document like html should extend this class
/// and implement
///
class ViteDocument {
  String content;
  ViteDocType docType;

  final List<ViteChange> _undoStack = [];

  ViteDocument({
    required this.content,
    this.docType = ViteDocType.plain,
  });

  ///
  /// Delete [length] characters from html
  ///
  void delete(int bodyIndex, int length) {
    if ((bodyIndex < 0) || (bodyIndex > content.length)) {
      print('delete($bodyIndex) out of range ${content.length}');
      return;
    }
    ViteChange change = ViteChange(action: ViteChangeAction.delete);
    change.bodyIndex = bodyIndex;
    change.newLength = 0;

    //--- Auto adjust length if exceeds body
    if (bodyIndex + length >= content.length) {
      change.removedText = content.substring(bodyIndex);
      content = content.substring(0, bodyIndex);
    } else {
      change.removedText = content.substring(bodyIndex, length);
      content = content.replaceRange(bodyIndex, bodyIndex + length, '');
    }
    _undoStack.add(change);
  }

  ///
  /// Insert [newText] at [index] into `body`
  ///
  void insert(int bodyIndex, String newHtml) {
    if ((bodyIndex < 0) || (bodyIndex > content.length)) {
      print('insert($bodyIndex) out of range ${content.length}');
      return;
    }
    ViteChange change = ViteChange(action: ViteChangeAction.insert);
    change.bodyIndex = bodyIndex;
    change.newLength = newHtml.length;
    content = content.replaceRange(bodyIndex, bodyIndex, newHtml);
    _undoStack.add(change);
  }

  ///
  ///
  ///
  void replace(int bodyIndex, int length, String replacement) {
    if ((bodyIndex < 0) || (bodyIndex > content.length)) {
      print('replace ($bodyIndex) out of range ${content.length}');
      return;
    }
    ViteChange change = ViteChange(action: ViteChangeAction.replace);
    change.bodyIndex = bodyIndex;
    change.removedText = content.substring(bodyIndex, length);
    change.newLength = replacement.length;
    content = content.replaceRange(bodyIndex, bodyIndex + length, replacement);
    _undoStack.add(change);
  }

  ///
  /// Undo last action. Returns `false` if nothing undone
  ///
  bool undo() {
    if (_undoStack.isEmpty) {
      return false;
    }
    ViteChange change = _undoStack.removeLast();
    if (change.action == ViteChangeAction.delete) {
      content = content.replaceRange(
          change.bodyIndex, change.bodyIndex, change.removedText);
    } else if (change.action == ViteChangeAction.insert) {
      content = content.replaceRange(change.bodyIndex,
          change.bodyIndex + change.newLength, change.removedText);
    } else if (change.action == ViteChangeAction.replace) {
      content = content.replaceRange(change.bodyIndex,
          change.bodyIndex + change.newLength, change.removedText);
    }
    return true;
  }

  @override
  String toString() =>
      '$docType with ${content.length} has ${_undoStack.length} undo actions';
}
