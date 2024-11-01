# Delta-Text Analysis

## Delta-Types

|= Type       =|= leading =|= trailing =|= added =|
|==============|===========|============|=========|
| Ins -  start |        "" |   previous |   added |
| Ins - middle |      lead |      trail |   added |
| Ins -    end |  previous |         "" |   added |
| Del -  start |        "" |      trail |      "" |
| Del - middle |      lead |      trail |      "" |
| Del -    end |      lead |         "" |      "" |
| Upd -  start |        "" |      trail |   added |
| Upd - middle |      lead |      trail |   added |
| Upd -    end |      lead |         "" |   added |

|= Type       =|= leading =|= trailing =|= added =|
|==============|===========|============|=========|
| Start  - Ins |        "" |   previous |   added |
| Start  - Del |        "" |      trail |      "" |
| Start  - Upd |        "" |      trail |   added |
| Middle - Ins |      lead |      trail |   added |
| Middle - Del |      lead |      trail |      "" |
| Middle - Upd |      lead |      trail |   added |
| End    - Ins |  previous |         "" |   added |
| End    - Del |      lead |         "" |      "" |
| End    - Upd |      lead |         "" |   added |

## Conclusions

* `added.isEmpty` -> delete
* `added.isNotEmpty` -> insert or update

Q: Should insert and update be handled identically?
A: No because insert always adds text to only one single text-node without modifying the tree

Q: How to determine if it's an insert?
A: Insert has: `added.isNotEmpty` AND `leading.length + trailing.length == previous.length`

## Determine Text-Node

A text-node can be determined by the cursor position or by some computed index.

```
IF cursor index is on first character of a text-node
AND (this character is a comma or space OR if the previous character is a line-break)
THEN the previous text-node will be used.
```

# Delta-Format Analysis

Formats can be changed at single cursor position or on a selected range of text.

A format change at single cursor position will be reset by any deletion or by
repositioning the cursor. It only has an effect on newly entered text
either from keyboard or by pasting the text.

A format change on a range selection will reformat the selected range of text.
