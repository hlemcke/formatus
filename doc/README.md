# FORMATUS → A plain Flutter Rich-Text-Editor with integrated Viewer

## Architecture

1. [FormatusBar] provides the formatting actions
2. [FormatusController] must be used as a [TextFormField] controller
3. [FormatusViewer] displays the formatted output as a [TextSpan] tree
4. Both `FormatusBar` and `FormatusController` must get the same `FocusNode` on creation
5. `FormatusController` manages a tree-like document [FormatusDocument]
6. `FormatusDocument` manages the formatting tree and all text nodes
7. Supported top-level tags are sections: h1, h2, h3, p
8. Top-level tags are separated by line-breaks
9. Top-level tags contain nested elements like plain text or formatting elements like `<b>`
10. Formatting elements can be nested
11. Ordered and unordered lists are supported
12. Anchors and Images can be integrated. Callbacks are provided to select them

## Storage Format

The formatted text

* is a HTML string containing a list of section tags
* starts with an opening top-level tag like `<h1>` or `<p>`
* ends with a closing top-level tag like `</p>`
