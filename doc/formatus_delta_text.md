# Delta-Text Analysis

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

## Conclusion

`added.isEmpty` -> delete
`added.isNotEmpty` -> insert or update

Q: Should insert and update be handled identically?
A: No because insert always adds text to only one single text-node
