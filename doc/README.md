# FORMATUS → A plain Flutter rich-text-editor

## Architecture

1. [FormatusBar] provides the formatting actions
2. [FormatusController] must be used as a [TextFormField] controller
3. Both `FormatusBar` and `FormatusController` must get the same `FocusNode` on creation
4. `FormatusController` manages a tree-like document [FormatusDocument]
5. `FormatusDocument` manages the formatting tree and all text nodes
6. Supported top-level tags are h1, h2, h3, p, ol, ul
7. Top-level tags are separated by a line-break. There are no other line-breaks.
8. Top-level tags contain nested elements like plain text or formatting elements like `<b>`
9. Formatting elements can be nested
10. Plain text elements are leaves of the tree. They cannot contain any nested element

## Storage Format

The formatted text

* is stored as a HTML body without the `body` tag
* starts with an opening top-level tag like `<h1>` or `<p>`
* ends with a closing top-level tag like `</p>`
