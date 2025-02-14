# Delta-Text Analysis

[DeltaText] is `false` if next string (`nextText)` is equal to previous string (`prevText`).

Q: Should insert and update be handled identically?
A: No because insert always adds text to only one single text-node without modifying the format-tree

Q: How to determine if it's a deletion?
A: Delete has: `plusText.isEmpty`

Q: How to determine if it's an insert?
A: Insert has: `plusText.isNotEmpty` AND `leadText + tailText == prevText`

## Initial Computations

1. all -> (prevSelection.start == 0) AND (prevText.length == prevSelection.end)
2. start -> NOT all AND ((prevSelection.start == 0) OR (nextSelection.start == 0))
   * headText = ''
   * tailText from end
   * plusText is substring of nextText minus tail
3. end -> NOT start AND ((prevSelection.end == prevText.length) OR (nextSelection.end == nextText.end))
   * tailText = ''
   * headText from start until prevSelection.start
   * plusText is substring of nextText minus head
4. middle -> NOT end
   * headText from start until prevSelection.start
   * tailText from end until prevSelection.end
   * plusText is substring of nextText minus head and minus tail

## Follow-up Computations

1. del -> plusText.isEmpty
2. ins -> NOT del AND (leadText + tailText == prevText)
3. upd -> NOT ins

## Delta-Types ordered by Type of Modification

|=    Type    =|= head =|= tail =|= plus =|
|==============|========|========|========|
| del - all    |     "" |     "" |     "" |
| del - start  |     "" |   tail |     "" |
| del - middle |   head |   tail |     "" |
| del - end    |   head |     "" |     "" |
| ins - all    |     "" |     "" |   plus |
| ins - start  |     "" |   prev |   plus |
| ins - middle |   head |   tail |   plus |
| ins - end    |   prev |     "" |   plus |
| upd - start  |     "" |   tail |   plus |
| upd - middle |   head |   tail |   plus |
| upd - end    |   head |     "" |   plus |

## Delta-Types ordered by Position of Modification

|=  Position  =|= head =|= tail =|= plus =|
|==============|========|========|========|
| all - del    |     "" |     "" |     "" |
| all - ins    |     "" |     "" |   plus |
| start - del  |     "" |   tail |     "" |
| start - ins  |     "" |   prev |   plus |
| start - upd  |     "" |   tail |   plus |
| middle - del |   head |   tail |     "" |
| middle - ins |   head |   tail |   plus |
| middle - upd |   head |   tail |   plus |
| end - del    |   head |     "" |     "" |
| end - ins    |   prev |     "" |   plus |
| end - upd    |   head |     "" |   plus |


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
