import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Insert FormatusAnchor in text', () {
    //---
    test('Append anchor to end of text', () {
      //--- given
      String formatted = '<p>This is a </p>';
      FormatusControllerImpl controller = FormatusControllerImpl(
        formattedText: formatted,
      );

      FormatusAnchor anchor = FormatusAnchor(href: 'www.abc.de', name: 'link');
      controller.selection = TextSelection(baseOffset: 10, extentOffset: 10);

      //--- when
      controller.anchorAtCursor = anchor;

      //--- then
      FormatusDocument doc = controller.document;
      TreeHelper.printAll(doc, 'Anchor appended');
      expect(doc.childCount, 1);
      expect(
        doc.results.formatted,
        '<p>This is a <a href="www.abc.de">link</a></p>',
      );
      expect(doc.results.plainText, 'This is a link');
      expect(doc[0].tag, Formatus.paragraph);
      FormatusNode section = doc[0];
      expect(section[0].text, 'This is a ');
      expect(section[1].tag, Formatus.anchor);
      expect(section[1].text, 'link');
    });

    test('Insert anchor in the middle of text', () {
      //--- given
      String formatted = '<p>This is cool!</p>';
      FormatusControllerImpl controller = FormatusControllerImpl(
        formattedText: formatted,
      );

      FormatusAnchor anchor = FormatusAnchor(href: 'www.abc.de', name: 'link ');
      controller.selection = TextSelection(baseOffset: 5, extentOffset: 5);
      controller.anchorAtCursor = anchor;

      //--- when
      FormatusDocument doc = controller.document;
      doc.computeResults();

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 3, reason: 'textNodes=$textNodes');
      expect(
        controller.document.results.formatted,
        '<p>This <a href="www.abc.de">link </a>is cool!</p>',
      );
      expect(doc.results.plainText, 'This link is cool!');
      expect(textNodes[0].formats, [Formatus.paragraph]);
      expect(textNodes[0].text, 'This ');
      expect(textNodes[1].formats, [Formatus.paragraph, Formatus.anchor]);
      expect(textNodes[1].text, 'link ');
      expect(textNodes[2].formats, [Formatus.paragraph]);
      expect(textNodes[2].text, 'is cool!');
    });

    test('Insert anchor at the start of text', () {
      //--- given
      String formatted = '<p>are cool!</p>';
      FormatusControllerImpl controller = FormatusControllerImpl(
        formattedText: formatted,
      );

      FormatusAnchor anchor = FormatusAnchor(
        href: 'www.abc.de',
        name: 'Links ',
      );
      controller.selection = TextSelection(baseOffset: 0, extentOffset: 0);
      controller.anchorAtCursor = anchor;

      //--- when
      controller.document.computeResults();

      //--- then
      FormatusDocument doc = controller.document;
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 2);
      expect(
        doc.results.formatted,
        '<p><a href="www.abc.de">Links </a>are cool!</p>',
      );
      expect(doc.results.plainText, 'Links are cool!');
      expect(textNodes[0].formats, [Formatus.paragraph, Formatus.anchor]);
      expect(textNodes[0].text, 'Links ');
      expect(textNodes[1].formats, [Formatus.paragraph]);
      expect(textNodes[1].text, 'are cool!');
    });
  });

  group('Insert FormatusImage in text', () {
    test('Append Image to end of text', () async {
      //--- given
      String formatted = '<p>Our logo: </p>';
      FormatusControllerImpl controller = FormatusControllerImpl(
        formattedText: formatted,
      );
      Uint8List imageBytes = await File('test_assets/logo.png').readAsBytes();
      FormatusImage image = FormatusImage(
        aria: 'Djarjo Logo',
        bytes: imageBytes,
        src: 'logo.png',
      );
      controller.selection = TextSelection(baseOffset: 10, extentOffset: 10);

      //--- when
      FormatusDocument doc = controller.document;
      TreeHelper.printAll(doc, 'no image yet');
      controller.imageAtCursor = image;
      TreeHelper.printAll(doc, 'image appended');

      //--- then
      expect(
        doc.results.formatted,
        '<p>Our logo: <img src="logo.png" aria-label="Djarjo Logo"/></p>',
      );
      expect(doc.results.plainText, 'Our logo: $imagePlaceholderChar');

      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 2);
      expect(textNodes[0].formats, <Formatus>{.paragraph});
      expect(textNodes[0].text, 'Our logo: ');
      expect(textNodes[1].formats, <Formatus>{.paragraph, .image});
    });

    test('Insert Image in the middle of text', () async {
      //--- given
      String formatted = '<p>This is a logo</p>';
      FormatusControllerImpl controller = FormatusControllerImpl(
        formattedText: formatted,
      );
      Uint8List imageBytes = await File('test_assets/logo.png').readAsBytes();
      FormatusImage image = FormatusImage(
        aria: 'Djarjo Logo',
        bytes: imageBytes,
        src: 'logo.png',
      );
      controller.selection = TextSelection(baseOffset: 5, extentOffset: 5);

      //--- when
      controller.imageAtCursor = image;

      //--- then
      FormatusDocument doc = controller.document;

      expect(
        doc.results.formatted,
        '<p>This <img src="logo.png" aria-label="Djarjo Logo"/>is a logo</p>',
      );
      expect(
        doc.results.plainText,
        'This ${imagePlaceholderChar}is a logo',
        reason: 'plainText inserts $imagePlaceholderChar at image position',
      );

      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 3);
      expect(textNodes[0].formats, [Formatus.paragraph]);
      expect(textNodes[0].text, 'This ');
      expect(textNodes[1].formats, <Formatus>[.paragraph, .image]);
      expect(textNodes[2].formats, [Formatus.paragraph]);
      expect(textNodes[2].text, 'is a logo');
    });

    test('Insert Image at start of text', () async {
      //--- given
      String formatted = '<p> Our logo</p>';
      FormatusControllerImpl controller = FormatusControllerImpl(
        formattedText: formatted,
      );
      Uint8List imageBytes = await File('test_assets/logo.png').readAsBytes();
      FormatusImage image = FormatusImage(
        aria: 'Djarjo Logo',
        bytes: imageBytes,
        src: 'logo.png',
      );
      controller.selection = TextSelection(baseOffset: 0, extentOffset: 0);

      //--- when
      controller.imageAtCursor = image;

      //--- then
      FormatusDocument doc = controller.document;
      TreeHelper.printAll(doc, 'image prefixed to text');

      expect(
        doc.results.formatted,
        '<p><img src="logo.png" aria-label="Djarjo Logo"/> Our logo</p>',
      );
      expect(
        doc.results.plainText,
        '$imagePlaceholderChar Our logo',
        reason: 'plainText inserts a placeholder at image position',
      );

      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 1);
      expect(textNodes[0].formats, [Formatus.paragraph]);
      expect(textNodes[0].text, ' Our logo');
    });
  });
}
