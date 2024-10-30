import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Text delta tests == insertions', () {
    ///
    test('text are identical', () {
      String text = 'identical';
      DeltaText delta = DeltaText.compute(previous: text, next: text);
      expect(delta.hasDelta, false);
      expect(delta.leading, text);
      expect(delta.added, '');
      expect(delta.trailing, '');
    });

    ///
    test('text is added at start', () {
      String added = 'added ';
      String prev = 'some Text';
      String next = added + prev;
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, '');
      expect(delta.added, added);
      expect(delta.trailing, prev);
    });

    ///
    test('text is appended to end', () {
      String prev = 'some Text';
      String added = ' appended';
      String next = prev + added;
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, prev);
      expect(delta.added, added);
      expect(delta.trailing, '');
    });

    ///
    test('text is inserted in middle', () {
      String leading = 'some ';
      String added = 'inserted ';
      String trailing = 'text';
      DeltaText delta = DeltaText.compute(
          previous: leading + trailing, next: leading + added + trailing);
      expect(delta.hasDelta, true);
      expect(delta.leading, leading);
      expect(delta.added, added);
      expect(delta.trailing, trailing);
    });
  });

  ///
  ///
  group('Text delta tests == deletions', () {
    ///
    test('text deleted at start', () {
      String prev = 'some text';
      String next = ' text';
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, '');
      expect(delta.added, '');
      expect(delta.trailing, ' text');
    });

    ///
    test('text deleted at end', () {
      String prev = 'some text';
      String next = 'some ';
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, next);
      expect(delta.added, '');
      expect(delta.trailing, '');
    });

    ///
    test('text deleted in middle', () {
      String prev = 'some text';
      String next = 'somext';
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, 'some');
      expect(delta.added, '');
      expect(delta.trailing, 'xt');
    });
  });

  ///
  ///
  group('Text delta tests == replacements', () {
    ///
    test('text replaced at start', () {
      String prev = 'some text';
      String next = 'other text';
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, '');
      expect(delta.added, 'other');
      expect(delta.trailing, ' text');
    });

    ///
    test('text replaced at end', () {
      String prev = 'some text';
      String next = 'some drink';
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, 'some ');
      expect(delta.added, 'drink');
      expect(delta.trailing, '');
    });

    ///
    test('text replaced in middle', () {
      String prev = 'some text';
      String next = 'somxxxext';
      DeltaText delta = DeltaText.compute(previous: prev, next: next);
      expect(delta.hasDelta, true);
      expect(delta.leading, 'som');
      expect(delta.added, 'xxx');
      expect(delta.trailing, 'ext');
    });
  });
}
