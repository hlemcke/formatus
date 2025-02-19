import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';

void main() {
  group('DeltaText - Inserts', () {
    ///
    test('text are identical', () {
      String text = 'identical';
      DeltaText delta = DeltaText(
          prevSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
          prevText: text,
          nextSelection: const TextSelection(baseOffset: 5, extentOffset: 5),
          nextText: text);
      expect(delta.type, DeltaTextType.none);
      expect(delta.headLength, -1);
      expect(delta.textAdded, '');
      expect(delta.tailLength, -1);
      expect(delta.tailLength, -1);
    });

    ///
    test('text is added at start', () {
      String added = 'added ';
      String prev = 'some Text';
      String next = added + prev;
      DeltaText delta = DeltaText(
          prevSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
          prevText: prev,
          nextSelection: TextSelection(
              baseOffset: added.length, extentOffset: added.length),
          nextText: next);
      expect(delta.type, DeltaTextType.insert);
      expect(delta.headLength, 0);
      expect(delta.textAdded, added);
      expect(delta.tailLength, prev.length);
      expect(delta.tailOffset, 0);
    });

    ///
    test('text is appended to end', () {
      String prev = 'some Text';
      String added = ' appended';
      String next = prev + added;
      DeltaText delta = DeltaText(
          prevSelection:
              TextSelection(baseOffset: prev.length, extentOffset: prev.length),
          prevText: prev,
          nextSelection:
              TextSelection(baseOffset: next.length, extentOffset: next.length),
          nextText: next);
      expect(delta.type, DeltaTextType.insert);
      expect(delta.headLength, prev.length);
      expect(delta.textAdded, added);
      expect(delta.tailLength, 0);
      expect(delta.tailOffset, prev.length);
    });

    ///
    test('insert inside', () {
      String head = 'some ';
      String added = 'inserted ';
      String tail = 'text';
      String prev = head + tail;
      String next = head + added + tail;
      DeltaText delta = DeltaText(
          prevSelection:
              TextSelection(baseOffset: head.length, extentOffset: head.length),
          prevText: prev,
          nextSelection: TextSelection(
              baseOffset: head.length + added.length,
              extentOffset: head.length + added.length),
          nextText: next);
      expect(delta.type, DeltaTextType.insert);
      expect(delta.headLength, head.length);
      expect(delta.textAdded, added);
      expect(delta.tailLength, tail.length);
      expect(delta.tailOffset, head.length);
    });

    ///
    test('insert at all', () {});
  });

  ///
  ///
  group('DeltaText - Deletes', () {
    ///
    test('text deleted at start', () {
      String prev = 'some text';
      String next = ' text';
      DeltaText delta = DeltaText(
          prevSelection:
              const TextSelection(baseOffset: 0, extentOffset: 'some'.length),
          prevText: prev,
          nextSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
          nextText: next);
      expect(delta.type, DeltaTextType.delete);
      expect(delta.headLength, 0);
      expect(delta.textAdded, '');
      expect(delta.tailLength, next.length);
      expect(delta.tailOffset, 4);
      expect(delta.textRemoved, 'some');
    });

    ///
    test('text deleted at end', () {
      String prev = 'some text';
      String next = 'some ';
      int nextLen = next.length;
      DeltaText delta = DeltaText(
          prevSelection:
              TextSelection(baseOffset: nextLen, extentOffset: prev.length),
          prevText: prev,
          nextSelection:
              TextSelection(baseOffset: nextLen, extentOffset: nextLen),
          nextText: next);
      expect(delta.type, DeltaTextType.delete);
      expect(delta.headLength, nextLen);
      expect(delta.textAdded, '');
      expect(delta.tailLength, 0);
      expect(delta.tailOffset, 9);
      expect(delta.textRemoved, 'text');
    });

    ///
    test('text deleted in middle', () {
      String prev = 'some text';
      String next = 'somext';
      DeltaText delta = DeltaText(
          prevSelection: const TextSelection(baseOffset: 4, extentOffset: 7),
          prevText: prev,
          nextSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
          nextText: next);
      expect(delta.type, DeltaTextType.delete);
      expect(delta.headLength, 4);
      expect(delta.textAdded, '');
      expect(delta.tailLength, 2);
      expect(delta.tailOffset, 7);
      expect(delta.textRemoved, ' te');
    });
  });

  ///
  ///
  group('DeltaText - Updates', () {
    ///
    test('text replaced at start', () {
      String prev = 'some text';
      String next = 'other text';
      DeltaText delta = DeltaText(
          prevSelection: const TextSelection(baseOffset: 0, extentOffset: 4),
          prevText: prev,
          nextSelection: const TextSelection(baseOffset: 5, extentOffset: 5),
          nextText: next);
      expect(delta.type, DeltaTextType.update);
      expect(delta.headLength, 0);
      expect(delta.textAdded, 'other');
      expect(delta.tailLength, ' text'.length);
      expect(delta.tailOffset, 4);
      expect(delta.textRemoved, 'some');
    });

    ///
    test('text replaced at end', () {
      String prev = 'some text';
      String next = 'some drink';
      int i = 'some '.length;
      int j = next.length;
      DeltaText delta = DeltaText(
          prevSelection:
              TextSelection(baseOffset: i, extentOffset: prev.length),
          prevText: prev,
          nextSelection: TextSelection(baseOffset: j, extentOffset: j),
          nextText: next);
      expect(delta.type, DeltaTextType.update);
      expect(delta.headLength, i);
      expect(delta.textAdded, 'drink');
      expect(delta.tailLength, 0);
      expect(delta.tailOffset, prev.length);
      expect(delta.textRemoved, 'text');
    });

    ///
    test('text replaced in middle', () {
      String prev = 'some text';
      String next = 'somxxxext';
      DeltaText delta = DeltaText(
          prevSelection: const TextSelection(baseOffset: 3, extentOffset: 6),
          prevText: prev,
          nextSelection: const TextSelection(baseOffset: 6, extentOffset: 6),
          nextText: next);
      expect(delta.type, DeltaTextType.update);
      expect(delta.headLength, 3);
      expect(delta.textAdded, 'xxx');
      expect(delta.tailLength, 3);
      expect(delta.tailOffset, 'some t'.length);
      expect(delta.textRemoved, 'e t');
    });
  });
}
