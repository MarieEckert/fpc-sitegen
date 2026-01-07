# the fpc-sitegen rewrite

All changes listed in here are slated for release v3.0

## things that are (still) annoying

- Formatting source documents
	- e.g.: escaping switches, escaping broken formatting
- Adding new features
	- Even after the rewrite, the sad unit is still pretty restrictive in
	  how I can expand on the format.
- The code (particularly uTranslator) is still very ugly and unwieldly.
	- Slowly migrate to ObjectPascal if I can't design it well without those
	  niceties.

## features that will be added/removed/changed

- `preformatted` blocks which, just like the `insert` switch, paste the contents
  in without any special handling.
- A nicer CLI, the current one is OK but it could be better.
	- Flags with long-names.
	- Much more styled diagnostic output.
- Whitespace handling should be made much saner.
	- Lines only containing switches should no longer insert linebreaks
	  **ever**.
- Mariebuild support will be removed, a simple Makefile will be added instead.
