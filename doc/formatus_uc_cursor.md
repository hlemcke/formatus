# Use Cases at Cursor Position

Describes use cases which can occur at current cursor position.

## Position Cursor

The cursor can be moved to another position with multiple keys.
The new cursor position will only update the selected format-keys.

## Change current top-level format

The top-level tag at current cursor position will be changed to the selected one.
This initiates a redraw.

## Change current format (not top-level)

[FormatusBar] remembers current selection and updates the display of the format-keys.

## Insert a line-break

If the user hits the enter key then the current top-level node will be split.
The part left of cursor position remains in current top-level node.
The part right of cursor will be moved into a new top-level node of format "paragraph".

## Insert Characters

By keyboard only single characters can be inserted but a whole string can be pasted.

## Delete Characters

By keyboard only a single character can be deleted.
Left of cursor with backspace-key or right of cursor with delete-key.
If a text-range is selected then any of both keys will remove the whole range.

## Update Characters

Can be done by selecting a text-range and pasting a string.
