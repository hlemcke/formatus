# Tree

'FormatusDocument' manages a tree structure starting with a root-node (like the HTML body tag).

* children of root are only section tags: h1, h2, h3 or p
* sections contain a list of leaf-nodes which may be inside an inline-format
* `text` nodes are leaf-nodes (have no children)


## Select text and modify inline format

<pre>
root
 └── para
      ├── "head " 
      ├── bold
      │    ├── "bold "
      │    └── italic
      │         └── "mixed italic"
      └ " tail"
</pre>

* `formatted` → "<p>head <b>bold <i>mixed italic</i></b> tail</p>"
* `plainText` → "head bold mixed italic tail"
