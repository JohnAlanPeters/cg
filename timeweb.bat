rem restart webby every so often
:loop
   taskkill /f /im cg.exe
   start /b "" \cg\cg.exe 0 do-server
   timeout 3600
goto loop
