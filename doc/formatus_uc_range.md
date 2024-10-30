# Use Cases for Range Selection

Describes use cases which can occur ahen a text range is selected.

## Position Cursor

The cursor can be moved to another position with multiple keys.
The new cursor position clears the range and updates the selected format-keys.

## Change current top-level format

Clears range, changes top-level format and initiates a redraw.

## Change current format (not top-level)

The selected format will be applied to the range.
This may result in a fully modified tree.
[FormatusBar] displays the selected format.

## Insert a Character

Clears range and applies same functionality as described in use case
on cursor position.
