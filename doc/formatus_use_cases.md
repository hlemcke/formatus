# Formatus - Use Cases

### Definitions

* `copied text` -> text copied from somewhere (=> clipboard contains a string which can be `pasted`)
* `cursor position` -> current position of cursor in whole text. If a text range is selected then it's the start of the selection
* `end` -> end of whole text (== text.length)
* `format-bar` -> a button bar with selectable formats
* `leading text` -> text in front of cursor position or selection
* `middle` -> somewhere in the text which is neither `start` nor `end`
* `selection` -> a selected range of text which may include `start` and / or `end`
* `start` -> start of whole text (== text[0])
* `top-level` -> node like h1 or paragraph
* `trailing text` -> text behind cursor position or selection

## Use Case - Save

`FormatusController` provides method `formattedText` to save the current text
including all formats into a string in html-format.

## Use Case - Position Cursor

The cursor position can be changed with the cursor keys
or by tapping the left mouse key at mouse position.

Position the cursor will update the settings in the format-bar.
If the cursor is at the end of a text-node then the format-bar
will display the format of the left text-node if the character
at cursor position is a space or comma. Otherwise the format-bar
will display the format of the right text-node.

Any selected text-range will be cleared.

## Use Case - Select Range

A range can be selected by multiple actions depending on current platform.
The selected text will be highlighted.
The format-bar will display the formats at selection start.

## Use Case - Toggle Top-Level Format

Changes the format of the current top-level node at cursor position
or at selection start.

## Use Case - Toggle Inline Format

If no text range is selected then the format-bar will only display the current change.

If a text range is selected then the format settings in the format-bar
will be compared to the selection start.

* IF a format is added THEN it will be added to all text-nodes within the selection
* IF a format is removed THEN it will be removed from all text-nodes within the selection

## Use Case - Insertions

Text can be inserted either single character via keyboard or by pasting a copied text.

Position of the inserted character or copied text text is always at cursor position.

If a range of text is selected then it will first be deleted before the new text will take its place.

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
format-bar. It this is identical to either the preceding or following text
then the new text will just be appended to the preceding text or inserted
at start of the following.
