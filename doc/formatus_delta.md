# Delta-Text Analysis

[DeltaText] is `false` if current string (`curText)` is equal to previous string (`prevText`).

Q: Should insert and update be handled identically?
A: No because insert always adds text to only one single text-node without modifying the format-tree

Q: How to determine if it's a deletion?
A: Delete has: `added.isEmpty`

Q: How to determine if it's an insert?
A: Insert has: `added.isNotEmpty` AND `leadText + tailText == prevText`

## Initial Computations

1. all -> (prevSelection.start == 0) AND (prevText.length == prevSelection.end)
2. start -> NOT all AND ((prevSelection.start == 0) OR (curSelection.start == 0))
   * head = ''
   * tail from end
   * added is substring of curText minus tail
3. end -> NOT start AND ((prevSelection.end == prevText.length) OR (curSelection.end == curText.end))
   * tail = ''
   * head from start until prevSelection.start
   * added is substring of curText minus head
4. middle -> NOT end
   * head from start until prevSelection.start
   * tail from end until prevSelection.end
   * added is substring of curText minus head and minus tail

## Follow-up Computations

1. del -> added.isEmpty
2. ins -> NOT del AND (leadText + tailText == prevText)
3. upd -> NOT ins

## Delta-Types ordered by Type of Modification

|=    Type    =|= head =|= tail =|= add =|
|==============|========|========|=======|
| del - all    |     "" |     "" |    "" |
| del - start  |     "" |   tail |    "" |
| del - middle |   head |   tail |    "" |
| del - end    |   head |     "" |    "" |
| ins - all    |     "" |     "" | added |
| ins - start  |     "" |   prev | added |
| ins - middle |   head |   tail | added |
| ins - end    |   prev |     "" | added |
| upd - start  |     "" |   tail | added |
| upd - middle |   head |   tail | added |
| upd - end    |   head |     "" | added |

## Delta-Types ordered by Position of Modification

|=  Position  =|= head =|= tail =|= add =|
|==============|========|========|=======|
| all - del    |     "" |     "" |    "" |
| all - ins    |     "" |     "" | added |
| start - del  |     "" |   tail |    "" |
| start - ins  |     "" |   prev | added |
| start - upd  |     "" |   tail | added |
| middle - del |   head |   tail |    "" |
| middle - ins |   head |   tail | added |
| middle - upd |   head |   tail | added |
| end - del    |   head |     "" |    "" |
| end - ins    |   prev |     "" | added |
| end - upd    |   head |     "" | added |

## Computations - Parts

* head -> 
## Computations - Type

* Delete -> added.isEmpty
* Insert -> added.isNotEmpty AND 

## Determine Text-Node

A text-node can be determined from cursor position or from some computed index.

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
