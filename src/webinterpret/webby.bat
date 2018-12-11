cd "\Program Files\cg\src\webinterpret"
@start cmd /c "python webinterpret.py" %*
..\..\cg.exe 0 fload \cg\src\webinterpret\dosock.f do-client
 
