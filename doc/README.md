# FORMATUS -> A plain Flutter rich-text-editor

## Architecture

1. [FormatusController] must be used for a [TextFormField] controller
2. [FormatusActionBar] provides the formatting actions
3. `FormatusActionBar` must be given the `FormatusController` on creation
4. `FormatusController` manages a tree-like document [FormatusDocument]
5. `FormatusDocument` contains a list of top-level formatting elements
6. Top-level formatting elements are h1, h2, h3, p
7. Top-level elements contain nested elements like plain text or formatting elements like `<b>`
8. Formatting elements can be nested
9. Plain text elements are leaves of the tree. They cannot contain any nested element

## Storage Format

The formatted text

* is stored as an html body without the `body` tag
* starts with an opening top-level tag like `<h1>` or `<p>`
* ends with a closing top-level tag like `/p`

## Use Cases at Cursor Position

1. Cursor placed somewhere in formatted text => formatting buttons are activated accordingly
2. Entering characters => inserted into text node of cursor position
3. Entering `newline` => if within `<p>` then insert `<br/>`, else create a new paragraph after
   current top-level element
4. Deleting characters => deleted from text node of cursor position. If text node becomes empty then
   it will be deleted. If parent node only contained the deleted text node then it will be deleted
   also (up to top-level element)
5. Changing top-level format => not possible
6. Changing inline format => Remember setting for newly entered characters

## Use Cases at Range Selection

1. Changing inline format =>

## TODOs

* publish to _pub.dev_
* write documentation

## TODOs on Single Cursor

* change inline formats => display formats => OK
* change alignment of top-level format to: left (default), center, right
* insert character => consider formats
* delete + text node gets empty => delete text node
* insert emoji from selectables => insert into current text node
* convert emoji name into emoji inline => insert into current text node

## TODOs at Range Selection

* activate inline format => change format of selected text
* activate top-level format => if top-level completely selected then change it else
  do nothing
* delete => delete all text and nodes in range
