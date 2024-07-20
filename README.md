# fpc-sitegen
A "static site generator" and replacement for sadhtml.

## About 
fpc-sitegen takes in a simple-ansi-document (see [sad](https://github.com/FelixEcker/sad)) and a
.sgt (sitegen template) to generate a final document.

Templates define formatting for every kind of SAD switch, see `data/template.sgt` for a simple
example of a template to convert to HTML.

## Usage
```
fpc-sitegen [-i <input file>] [-o <output file>] [additional options]
```

### Options
```
-i <input file>
    Specify the input file. If not set, fpc-sitegen will read from STDIN.
-o <output file>
    Specify the output file. If not set, fpc-sitegen will read from STDERR.
-t <template file>
    Specify the template to be used for generation
```
