# Formatus Parser

## Lists

`Formatus` supports ordered (`<ol>`) and unordered (`<ul>`) lists:

'''
<ol><li>First item</li><li>Second entry</li><li>Item three</li></ol>
'''

Parsing this results in 5 [FormatusNode]:

1. `<ol><li>` -> "First item"
2. line-break
3. `<ol><li>` -> "Second entry"
4. line-break
5. `<ol><li>` -> "Item three"