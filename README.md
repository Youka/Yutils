Yutils - an ASS typeset utilities library
=========================================
Requirements:
-------------
* LuaJIT

Files:
------
* Yutils.lua (*the library*)
* README.md (*this file*)
* tests/ (*folder with example scripts of Yutils' usage*)
* luajit/ (*LuaJIT compiler&interpreter for executing this project's files*)
* .gitignore (*files to ignore by Git*)
* .gitattributes (*how Git should handle files*)
* .gitmodules (*submodules of this project*)

Docs:
-----
See tests and Yutils.lua first lines.

TODO:
-----
* add shape.to_outline optional dimension size arguments
* add math trim
* remove get_* methods (renaming/merging)
* split decode sublibrary to font & bitmap
* add fonts list
* add bitmap tracer
* add ASS sublibrary (color/alpha conv, parser)
* write detailed docs