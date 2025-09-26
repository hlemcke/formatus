# Text Modifications

Text modification includes adding text, removing text and changing text format.

Adding text may require removing first (in case a text-range range was selected).


## Examples

<p>abc <u>def</u> ghi</p>

### Collapsed && single node && same format

* [0,0] added: "XY" => <p>XYabc <u>def</u> ghi</p>
* [1,1] added: "XY" => <p>aXYbc <u>def</u> ghi</p>
* [4,4] added: "XY" => <p>abc XY<u>def</u> ghi</p>

### Expanded && single node && same format

* [0,1] added: "XY" => <p>XYbc <u>def</u> ghi</p>
* [1,2] added: "XY" => <p>aXYc <u>def</u> ghi</p>
* [3,4] added: "XY" => <p>abcXY<u>def</u> ghi</p>

### Collapsed && single node && different format

* [0,0] added: "XY" => <p><b>XY</b>abc <u>def</u> ghi</p>
* [1,1] added: "XY" => <p>a<b>XY</b>bc <u>def</u> ghi</p>
* [4,4] added: "XY" => <p>abc <b>XY</b><u>def</u> ghi</p>

### Collapsed && multiple node && same format

* [0,5] added: "XY" => <p>XY<u>ef</u> ghi</p>
* [1,6] added: "XY" => <p>aXY<u>f</u> ghi</p>

### Range && single node && different format

* [0,1] added: "XY" => <p><b>XY</b>bc <u>def</u> ghi</p>
* [1,2] added: "XY" => <p>a<b>XY</b>c <u>def</u> ghi</p>
* [3,4] added: "XY" => <p>abc<b>XY</b><u>def</u> ghi</p>


## Algorithm for Text Modification

1. Compute headMeta and tailMeta
2. remove nodes between headMeta and tailMeta excluding them
3. if ( tailMeta > headMeta )
   => delete trailing text at headMeta
   => append leading text from tailMeta
   => remove tailMeta
   => forward section from headMeta until lineFeed
4. if ( tailMeta == headMeta ) => delete text between start and end
5. if text added && same formats => insert text at headMeta.start
6. if text added && different formats
    => create new node with added text and mix formats
    => if start > 0 && start < length => split current node
    => insert new node at headMeta or at headMeta+1 if start > 0

## Algorithm for Section Modification

1. Compute headMeta and tailMeta
2. update section in all nodes behind tailMeta until lineFeed
2. loop all nodes from tailMeta until headMeta (backwards!)
   => if node is linefeed then delete node
   => else update node section
3. update section in all nodes in front of headMeta until lineFeed

## Algorithm for Inline Modification

Requires selected text-range.
Updates exactly one format.

1. Set `apply=true` if not all nodes already contain format
2. Compute headMeta and tailMeta
3. if tailMeta 0 < offset && offset < length then split tailMeta
4. if headMeta 0 < offset && offset < length then split headMeta
   => increment tailMeta and headMeta nodeIndex
5. update format in all nodes from headMeta to tailMeta including both
