# Lists

`Formatus` allows to create and edit both ordered and unordered lists.

## Formatus Node

Each single list item is a `FormatusNode`.
Its section (first format) is either `ol` for an ordered list or `ul` for an unordered list.
The _list item_ "`li`" required by html is always the second format.

## Formatted Text

The formatted text of an ordered list conforms to html.
An unordered list just has `ul` instead of `ol`.
```
<ol><li>apple</li><li>banana</li></ol>
```

## Plain Text

Plain text for a list item starts with a single whitespace representing the format `ol` or `ul`.
If this whitespace gets deleted then the list item changes its section to `p`.

## Flutter TextField

The section format (`ol` or `ul`) is represented by a `WidgetSpan` (prefix).
The `WidgetSpan` contains either "* " for an unordered list item or "n. " for an ordered list item.
This prefix is followed by optional inline formats and the text of the list item.
