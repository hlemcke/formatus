# Colors

`Formatus` can color character sequences in different colors.

A color is handled similar to any other inline format.

## Formatus Node

A _standard_ inline format only requires the format information (`Formatus`).
A _color_ additionally requires the color value.
This requirement is solved by putting the color value into the `FormatusNode`
and the color format into any position of the nodes _formats_.

## Formatted Text

Color is formatted with tag `div` like: `<div style="color: #ffff9800;">` for orange. 

## Plain Text

The characters of colored text are just put into plain text as they are.
