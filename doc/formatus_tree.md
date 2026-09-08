# Tree

'FormatusDocument' is a tree-like structure starting with a root-node (like an HTML body tag).

    * `text` nodes are the only existing leaf-nodes (have no children)


## Select text and modify inline format

<pre>
root
 └ para
    ├ text "head " 
    ├ bold
    |  ├ text "bold "
    |  └ italic
    |     └ text "mixed italic"
    └ text " tail"
</pre>

* `formatted` → "<p>head <b>bold <i>mixed italic</i></b> tail</p>"
* `plainText` → "head bold mixed italic tail"

### Remove inline format

Select word "italic" (17, 23) and remove format italic results in:

<pre>
root
 └ para
    ├ text "head " 
    ├ bold
    |  ├ text "bold "
    |  ├ italic
    |  |  └ text "mixed "
    |  └ text "italic"
    └ text " tail"
</pre>

* `formatted` → "<p>head <b>bold <i>mixed </i>italic</b> tail</p>"
* `plainText` → "head bold mixed italic tail"
