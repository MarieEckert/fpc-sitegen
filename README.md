# fpc-sitegen
A "static site generator" and replacement for sadhtml.

## About
fpc-sitegen takes in a simple-ansi-document (see [sad](https://github.com/FelixEcker/sad)) and a
.sgt (sitegen template) to generate a final document.

Templates define the basic formatting for certain kinds of "switches", see `data/template.sgt` for
a simple example of a template to convert to HTML.

### Prerequisites for Building

fpc-sitegen requires the following programs for building:

* mariebuild (build system)
* fpc (>=3.2.2)
* asciidoctor (optional, used for manpages)

## Usage
```
fpc-sitegen [-i <input file>] [-o <output file>] [additional options]
```

### Options
```
-V
  Print the version and exit.
-i <input file>
  Specify the input file. If not set, fpc-sitegen will read from STDIN.
-o <output file>
  Specify the output file. If not set, fpc-sitegen will write to STDOUT.
-t <template file>
  Specify the template to be used for generation
-a <mode>
  Automatically insert a html br tag
  mode can be:
    * lf : Causes the tag to be inserted after every linefeed
    * el : Causes the tag to be inserted at every empty line
-d <name> <file>
  Define a name associated to a file for the insert switch.
```

## Templates
The custom template format is really simple, it is split up into several smaller
format blocks marked with labels. These blocks are:

* `title-format` – Format for contents of the `title` switch
* `head-format` – Format for contents of the `head` switch
* `sub-head-format` – Format for the contents of the `sub-head` switch
* `text-format` – Format for text contents of a section
* `section-format` – Format for sections
* `root-section-format` – Format for the (implicitly created) root-section
* `output-format` – Base format around the actual contents

A format block is started using the name of the block followed by a colon, e.g.
`title-format:`. Blocks end when another label is encountered or when the
template ends.

There are also a few default "markers" which can be insereted within a format.
By far the most important being the `$$CONTENT$$` marker, which inserts the
expected content.

**NOTE:** This marker can only be used *once* per format.

Other markers which are supported are:
* `$$DOCUMENT_TITLE$$` – The title of the document, as set with the `title` switch
* `$$SECTION_NAME$$` – The name of the current section
