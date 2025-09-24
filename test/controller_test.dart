import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';

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
      expect(controller.document.textNodes.length, 2);
      expect(
        controller.document.results.formattedText,
        '<p>This is a <a href="www.abc.de">link</a></p>',
      );
      expect(controller.document.results.plainText, 'This is a link');
      expect(controller.document.textNodes.length, 2);
      expect(controller.document.textNodes[0].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[0].text, 'This is a ');
      expect(controller.document.textNodes[1].formats, [
        Formatus.paragraph,
        Formatus.anchor,
      ]);
      expect(controller.document.textNodes[1].text, 'link');
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
      controller.document.computeResults();

      //--- then
      expect(controller.document.textNodes.length, 3);
      expect(
        controller.document.results.formattedText,
        '<p>This <a href="www.abc.de">link </a>is cool!</p>',
      );
      expect(controller.document.results.plainText, 'This link is cool!');
      expect(controller.document.textNodes[0].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[0].text, 'This ');
      expect(controller.document.textNodes[1].formats, [
        Formatus.paragraph,
        Formatus.anchor,
      ]);
      expect(controller.document.textNodes[1].text, 'link ');
      expect(controller.document.textNodes[2].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[2].text, 'is cool!');
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
      expect(controller.document.textNodes.length, 2);
      expect(
        controller.document.results.formattedText,
        '<p><a href="www.abc.de">Links </a>are cool!</p>',
      );
      expect(controller.document.results.plainText, 'Links are cool!');
      expect(controller.document.textNodes[0].formats, [
        Formatus.paragraph,
        Formatus.anchor,
      ]);
      expect(controller.document.textNodes[0].text, 'Links ');
      expect(controller.document.textNodes[1].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[1].text, 'are cool!');
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
      controller.imageAtCursor = image;

      //--- then
      expect(controller.document.textNodes.length, 2);
      expect(
        controller.document.results.formattedText,
        '<p>Our logo: <img src="logo.png" aria-label="Djarjo Logo"></img></p>',
      );
      expect(controller.document.results.plainText, 'Our logo: ');
      expect(controller.document.textNodes.length, 2);
      expect(controller.document.textNodes[0].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[0].text, 'Our logo: ');
      expect(controller.document.textNodes[1].formats, [
        Formatus.paragraph,
        Formatus.image,
      ]);
      expect(controller.document.textNodes[1].attribute, 'logo.png');
      expect(controller.document.textNodes[1].text, '');
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
      expect(controller.document.textNodes.length, 3);
      expect(
        controller.document.results.formattedText,
        '<p>This <img src="logo.png" aria-label="Djarjo Logo"></img>is a logo</p>',
      );
      expect(controller.document.results.plainText, 'This is a logo');
      expect(controller.document.textNodes.length, 3);
      expect(controller.document.textNodes[0].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[0].text, 'This ');
      expect(controller.document.textNodes[1].formats, [
        Formatus.paragraph,
        Formatus.image,
      ]);
      expect(controller.document.textNodes[1].attribute, 'logo.png');
      expect(controller.document.textNodes[1].text, '');
      expect(controller.document.textNodes[2].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[2].text, 'is a logo');
    });

    test('Insert Image at the start of text', () async {
      //--- given
      String formatted = '<p>Our logo</p>';
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
      expect(controller.document.textNodes.length, 2);
      expect(
        controller.document.results.formattedText,
        '<p><img src="logo.png" aria-label="Djarjo Logo"></img>Our logo</p>',
      );
      expect(controller.document.results.plainText, 'Our logo');
      expect(controller.document.textNodes.length, 2);
      expect(controller.document.textNodes[0].formats, [
        Formatus.paragraph,
        Formatus.image,
      ]);
      expect(controller.document.textNodes[0].attribute, 'logo.png');
      expect(controller.document.textNodes[0].text, '');
      expect(controller.document.textNodes[1].formats, [Formatus.paragraph]);
      expect(controller.document.textNodes[1].text, 'Our logo');
    });
  });
}
