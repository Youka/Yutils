Yutils - an ASS typeset utilities library
#########################################
Requirements:
LuaJIT
-----------------------------------------
Files:
Yutils.lua (the library)
README.txt (this file)
tests/ (folder with example scripts of Yutils' usage)
.gitignore (files to ignore by Git)
-----------------------------------------
Notes:
- all shape functions work with integer shapes
- Yutils.shape.to_pixels downscales the given shape to 1/8 size (to calculate anti-aliasing)
- FONT.text_to_shape returns the shape with 8x size (to save precision)