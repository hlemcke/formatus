import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

class TestHelper {
  ///
  /// &lt;p>&lt;b>abc&lt;/b> def &lt;i>ghi&lt;/i>&lt;/p>
  ///
  /// Plain = "abc def ghi"
  ///
  static FormatusDocument buildSingleSectionTree() {
    FormatusDocument doc = FormatusDocument.empty();
    FormatusNode t1 = FormatusNode(tag: .text, text: 'abc');
    FormatusNode b1 = FormatusNode(tag: .bold)..appendChild(t1);
    FormatusNode p = FormatusNode(tag: .paragraph)..appendChild(b1);
    doc.root.children.clear();
    doc.root.appendChild(p);
    FormatusNode t2 = FormatusNode(tag: .text, text: ' def ');
    p.appendChild(t2);
    FormatusNode t3 = FormatusNode(tag: .text, text: 'ghi');
    FormatusNode i3 = FormatusNode(tag: .italic)..appendChild(t3);
    p.appendChild(i3);
    doc.computeResults();
    return doc;
  }

  ///
  /// &lt;p>abc&lt;ol>&lt;li>First&lt;/li>&lt;Second&lt/li>&lt;/ol>&lt;/p>>
  ///
  /// Plain = "abc\n1. First\n2. Second\ndef"
  ///
  static FormatusDocument buildTreeWithList() {
    FormatusDocument doc = FormatusDocument.empty();
    FormatusNode t1 = FormatusNode(tag: .text, text: 'abc');
    FormatusNode p = FormatusNode(tag: .paragraph)..appendChild(t1);
    doc.root.children.clear();
    doc.root.appendChild(p);
    FormatusNode first = FormatusNode(tag: .text, text: 'First');
    FormatusNode li0 = FormatusNode(tag: .listItem)..appendChild(first);
    FormatusNode ol = FormatusNode(tag: .orderedList)..appendChild(li0);
    p.appendChild(ol);
    FormatusNode second = FormatusNode(tag: .text, text: 'Second');
    FormatusNode li1 = FormatusNode(tag: .listItem)..appendChild(second);
    ol.appendChild(li1);
    FormatusNode t2 = FormatusNode(tag: .text, text: 'def');
    p.appendChild(t2);
    doc.computeResults();
    return doc;
  }
}
