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

## Insert a Character

The system knows about a character insert if the new text is longer than the old one.
On character insert the following algorithm is executed:

1. Determine text node at cursor position minus one (before character entering)
2. Obtain path from root to modified text node
3. Compute difference of formats in path and formats selected by user
4. If there is no format difference then just insert the character into the current text node
5. If there is a difference then 