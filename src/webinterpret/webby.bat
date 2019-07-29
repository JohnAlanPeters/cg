cd "\cg\src\webinterpret"
@start cmd /c "webinterpret.py" %*
..\..\cg.exe 0 fload \cg\src\webinterpret\dosock.f do-client
 
