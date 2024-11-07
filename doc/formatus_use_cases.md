# Formatus - Use Cases

### Definitions

* `body` -> object within text which is neither `head` nor `tail`
* `caret index` -> index of current cursor position in whole text.
  If a text range is selected then `caret index` is the start of the selection
* `copied text` -> text copied from somewhere (=> clipboard contains a string which can be `pasted`)
* `end` -> length of whole text
* `format-bar` -> a button bar with selectable formats
* `head` -> object left of cursor position
* `selection` -> a selected range of text which may include `start` and / or `end`
* `tail` -> object right of cursor position
* `top-level` -> node like `h1` or `paragraph`

## Use Case - Save

`FormatusController` provides method `formattedText` to save the current text
including all formats into a string. This string can be persisted and given
as input to a `FormatusController`.

## Use Case - Position Caret

The caret position can be changed with the cursor keys
or by tapping the left mouse key at mouse position.

Positioning the caret clears any selected text-range.

Positioning the caret will update the settings in the format-bar.
If the caret is at the end of a text-node
and the character at that index is a space or a comma
then the format-bar will display the formats of the left text-node.
Otherwise the format-bar will display the formats of the right text-node.

## Use Case - Select Range

A range can be selected by multiple actions depending on current platform.
The selected text will be highlighted.
The format-bar will display the formats at selection start.

## Use Case - Toggle Top-Level Format

If the current top-level format is deactivated then nothing will happen.
If another top-level format is activated then the format
of the current top-level node will be set to the selected format.

## Use Case - Toggle Inline Format

If no text range is selected then the format-bar will only display the current settings.

If a text range is selected then the format settings in the format-bar
will be compared to the formats at selection start or at caret index.

* IF a format is added THEN it will be added to all text-nodes within the selection
* IF a format is removed THEN it will be removed from all text-nodes within the selection

## Use Case - Insertions

Text can be inserted either single character via keyboard
or by pasting a copied text.

Position of the inserted character or copied text text is always at caret index.

If a range of text is selected then it will first be deleted
before the new text will take its place.

The format of the inserted character or pasted text will be the current format settings.

### Insert a Line-Break

Hitting the `Enter`-key can happen anywhere in the whole text.
This action will split the current top-level node into the part left of the split
and into a newly created top-level node with format `paragraph` containing
the right part of the split.

## Use Case - Deletions

A deletion is performed by hitting:

* backspace key to delete character left of cursor position or to delete a selection
* delete key to delete character right of cursor position or to delete a selection

If the text following the deleted text and the text preceding it have the same
formats then both text-nodes will be combined into one.

### Delete a Line-Break

If a `line-break` gets deleted then the text of the the top-level node
following the `line-break` will be appended to the top-level node preceding
the `line-break`.

## Use Case - Updates

An update happens if a text-range is selected and a character will be entered
or some copied text will be inserted.

The inserted character or copied text will have the format settings from the
format-bar which are the formats at start of the selected range of text.
