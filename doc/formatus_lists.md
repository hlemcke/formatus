# Lists

Formatus allows to create and edit ordered and unordered lists.

## Formatus Node

Each single list item is a `FormatusNode`.
Its section (first format) is either `ol` for an ordered list or `ul` for an unordered list.
The _list item_ "`<li>`" required by html is only created into the formatted text.

## Formatted Text

The formatted text of an ordered list conforms to html:
```
<ol><li>apple</li><li>banana</li></ol>
```

Formatted text of an unordered list:
```
<ul><li>apple</li><li>banana</li></ul>
```

## Plain Text

Plain text for an ordered list starts with "  n. " with two whitespaces prefixing the counter
and suffixing it.

Plain text for an unordered list starts with " * " with one whitespace prefixing and one
suffixing the dot.

## Flutter TextField

Since `TextField` does not properly