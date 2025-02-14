## 1.2.1
* Added optional `onChanged` parameter to [FormatusController] which will be invoked with updated
  `formattedText`

## 1.2.0

* Added `Formatus.gap` to allow a small gap in formatting actions. If nothing is supplied
  to `FormatusBar.actions` then this gap will separate section formats from inline format
* Separated implementation of [FormatusBar] and [FormatusController] from their public API
* Fixed bug when deleting last character in a single text node
* Changed example/main.dart to set `TextFormField.showCursor: true` because _Flutter_
  does not position cursor correctly when entering spaces at end of text

## 1.1.0

* Modified constructor of `FormatusController` to be compliant to `TextEditingController` 
* Fixed a couple of bugs when inserting characters into an empty field
* Fixed bug in computation of text-node at end of node or section
* Implemented automatic update of output fields in example

## 1.0.1+1

* Updated _description_ in `pubspec.yaml` to conform to range 60-180
* Fixed cleanup of section format settings
* Exporting _FormatusViewer_

## 1.0.1

* Added `FormatusViewer` to display formatted text (see example about usage)
* Fixed a bug when appending a new paragraph and then entering text

## 1.0.0

* Initial release
