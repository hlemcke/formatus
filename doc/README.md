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
* ends with a closing top-level tag like `</p>`

## TODOs

* publish to _pub.dev_
* write documentation

## Enhancement: Markdown

The `Formatus` editor also supports `Markdown`. Following elements are supported:

* `Heading` -> `# heading1`, `## heading 2`, `### heading 3`
* `Italic`  -> `*italic text*`
* `Bold`    -> `**bold text**`
* `Underline` -> `_underlined text_`
* `Line through` -> `~~lined through text~~`
* `Subscript` -> `H~2~O`
* `Superscript` -> `a^2^ + b^2^ = c^2^`
* `Horizontal rule` -> `---` as a single line with an empty line above
* `Link` -> `[title](https://formatus.github.com)`
* `Ordered list` -> `1. First item`
* `Unordered list` -> `* item`
* `Emoji` -> `That's funny :joy:` renders an emoji by its name
* `Task list` -> `[x] completed\n[ ] still open`
