import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_node.dart';
import 'package:formatus/src/formatus/formatus_results.dart';

void main() {
  Formatus b = Formatus.bold;
  Formatus h1 = Formatus.header1;
  Formatus i = Formatus.italic;
  Formatus p = Formatus.paragraph;
  Formatus s = Formatus.strikeThrough;
  Formatus u = Formatus.underline;

  group('Format-Optimizer - Single Section', () {
    //---
    test('Format-Optimizer - Single Section with 3 inlines', () {
      //--- given
      List<FormatusNode> nodes = [
        FormatusNode(formats: [h1, b, u, i], text: "h1-bui"),
        FormatusNode(formats: [h1, b, i, s], text: "h1-bis"),
      ];
      FormatusResults results = FormatusResults(textNodes: []);

      //--- when
      results.optimizeFormats(nodes);

      //--- then
      expect(nodes[0].formats, [h1, b, i, u]);
      expect(nodes[1].formats, [h1, b, i, s]);
    });
    //---
    test('Format-Optimizer - Single Section with 0 and 2 inlines', () {
      //--- given
      List<FormatusNode> nodes = [
        FormatusNode(formats: [h1], text: "h1"),
        FormatusNode(formats: [h1, s, b], text: "h1-sb"),
      ];
      FormatusResults results = FormatusResults(textNodes: []);

      //--- when
      results.optimizeFormats(nodes);

      //--- then
      expect(nodes[0].formats, [h1]);
      expect(nodes[1].formats, [h1, b, s]);
    });
    //---
    test('Format-Optimizer - Single Section with 1 and 0 inlines', () {
      //--- given
      List<FormatusNode> nodes = [
        FormatusNode(formats: [h1, b], text: "h1-b"),
        FormatusNode(formats: [h1], text: "h1"),
      ];
      FormatusResults results = FormatusResults(textNodes: []);

      //--- when
      results.optimizeFormats(nodes);

      //--- then
      expect(nodes[0].formats, [h1, b]);
      expect(nodes[1].formats, [h1]);
    });
    //---
    test('Format-Optimizer - Single Section with 3 and 2 inlines', () {
      //--- given
      List<FormatusNode> nodes = [
        FormatusNode(formats: [h1, b, u, i], text: "h1-bui"),
        FormatusNode(formats: [h1, s, b], text: "h1-sb"),
      ];
      FormatusResults results = FormatusResults(textNodes: []);

      //--- when
      results.optimizeFormats(nodes);

      //--- then
      expect(nodes[0].formats, [h1, b, i, u]);
      expect(nodes[1].formats, [h1, b, s]);
    });
  }, skip: true);
  group('Format-Optimizer - 1 Section with 3 nodes', () {
    //---
    test('Format-Optimizer - 1 Section - 3 nodes with ordered formats', () {
      //--- given
      List<FormatusNode> nodes = [
        FormatusNode(formats: [p, u, b], text: "h1-ub"),
        FormatusNode(formats: [p, b, i, s], text: "h1-bi"),
        FormatusNode(formats: [p, u, i, b], text: "h1-sib"),
      ];
      FormatusResults results = FormatusResults(textNodes: []);

      //--- when
      results.optimizeFormats(nodes);

      //--- then
      expect(nodes[0].formats, [p, b, u]);
      expect(nodes[1].formats, [p, b, i, s]);
      expect(nodes[2].formats, [p, b, i, u]);
    });
    //---
    test('Format-Optimizer - 1 Section - 3 nodes with mixed formats', () {
      //--- given
      List<FormatusNode> nodes = [
        FormatusNode(formats: [p, u, b], text: "h1-ub"),
        FormatusNode(formats: [p, i, s], text: "h1-bi"),
        FormatusNode(formats: [p, u, i, b], text: "h1-sib"),
      ];
      FormatusResults results = FormatusResults(textNodes: []);

      //--- when
      results.optimizeFormats(nodes);

      //--- then
      expect(nodes[0].formats, [p, b, u]);
      expect(nodes[1].formats, [p, b, i, s]);
      expect(nodes[2].formats, [p, b, i, u]);
    });
    //---
    test('Format-Optimizer - 1 Section - 4 nodes with mixed formats', () {
      //--- given
      List<FormatusNode> nodes = [
        FormatusNode(formats: [p, u, b], text: "h1-ub"),
        FormatusNode(formats: [p, i, b], text: "h1-ib"),
        FormatusNode(formats: [p, u, s], text: "h1-us"),
        FormatusNode(formats: [p, i, s, b], text: "h1-isb"),
      ];
      FormatusResults results = FormatusResults(textNodes: []);

      //--- when
      results.optimizeFormats(nodes);

      //--- then
      expect(nodes[0].formats, [p, b, u]);
      expect(nodes[1].formats, [p, b, i]);
      expect(nodes[2].formats, [p, s, u]);
      expect(nodes[3].formats, [p, s, i, b]);
    });
  }, skip: true);
}
