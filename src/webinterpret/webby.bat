cd "\cg\src\webinterpret"
@start cmd /c "python webinterpret.py" %*
..\..\cg.exe 0 fload dosock.f do-client
 
