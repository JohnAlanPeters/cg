rem restart webby every so often
rem delay on boot
timeout 30
:loop
   taskkill /f /im cg.exe
   start /b "" \cg\cg.exe 0 do-server
   timeout 3600
goto loop
