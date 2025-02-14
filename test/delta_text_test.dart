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
      expect(delta.position, DeltaTextPosition.unknown);
      expect(delta.type, DeltaTextType.none);
      expect(delta.headText, '');
      expect(delta.plusText, '');
      expect(delta.tailText, '');
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
      expect(delta.position, DeltaTextPosition.start);
      expect(delta.type, DeltaTextType.insert);
      expect(delta.headText, '');
      expect(delta.plusText, added);
      expect(delta.tailText, prev);
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
      expect(delta.position, DeltaTextPosition.end);
      expect(delta.type, DeltaTextType.insert);
      expect(delta.headText, prev);
      expect(delta.plusText, added);
      expect(delta.tailText, '');
    });

    ///
    test('insert at middle', () {
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
      expect(delta.position, DeltaTextPosition.middle);
      expect(delta.type, DeltaTextType.insert);
      expect(delta.headText, head);
      expect(delta.plusText, added);
      expect(delta.tailText, tail);
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
      expect(delta.position, DeltaTextPosition.start);
      expect(delta.type, DeltaTextType.delete);
      expect(delta.headText, '');
      expect(delta.plusText, '');
      expect(delta.tailText, ' text');
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
      expect(delta.position, DeltaTextPosition.end);
      expect(delta.type, DeltaTextType.delete);
      expect(delta.headText, next);
      expect(delta.plusText, '');
      expect(delta.tailText, '');
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
      expect(delta.position, DeltaTextPosition.middle);
      expect(delta.type, DeltaTextType.delete);
      expect(delta.headText, 'some');
      expect(delta.plusText, '');
      expect(delta.tailText, 'xt');
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
      expect(delta.position, DeltaTextPosition.start);
      expect(delta.type, DeltaTextType.update);
      expect(delta.headText, '');
      expect(delta.plusText, 'other');
      expect(delta.tailText, ' text');
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
      expect(delta.position, DeltaTextPosition.end);
      expect(delta.type, DeltaTextType.update);
      expect(delta.headText, 'some ');
      expect(delta.plusText, 'drink');
      expect(delta.tailText, '');
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
      expect(delta.position, DeltaTextPosition.middle);
      expect(delta.type, DeltaTextType.update);
      expect(delta.headText, 'som');
      expect(delta.plusText, 'xxx');
      expect(delta.tailText, 'ext');
    });
  });
}
