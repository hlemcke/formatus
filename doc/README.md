# FORMATUS -> A plain Flutter rich-text-editor

## Architecture

1. [FormatusController] must be used as a [TextFormField] controller
2. [FormatusActionBar] provides the formatting actions
3. `FormatusActionBar` must be given the `FormatusController` on creation
4. `FormatusController` manages a tree-like document [FormatusDocument]
5. `FormatusDocument` manages the formatting tree and all text nodes
6. Supported top-level tags are h1, h2, h3, p
7. Top-level tags are separated by a line-break. There are no other line-breaks.
8. Top-level tags contain nested elements like plain text or formatting elements like `<b>`
9. Formatting elements can be nested
10. Plain text elements are leaves of the tree. They cannot contain any nested element

## Storage Format

The formatted text

* is stored as an html body without the `body` tag
* starts with an opening top-level tag like `<h1>` or `<p>`
* ends with a closing top-level tag like `/p`

## Additional Information

* See `use cases at cursor position` in formatus_uc_cursor.md
* See `use cases at range selection` in formatus_uc_range.md

## TODOs

* publish to _pub.dev_
* write documentation

## TODOs for Cursor Position

* change top level format => update format of current top level node
* change inline formats => display formats => OK
* change alignment of top-level format to: left (default), center, right
* insert character => consider formats
* delete + text node gets empty => rearrange whole tree
* insert emoji from some list => insert into current text node
* convert emoji name into emoji inline => insert into current text node

## TODOs for Range Selection

* change inline format => change format of selected text
* change top-level format => disabled if a range is selected
* delete => delete all text and nodes within selected range
