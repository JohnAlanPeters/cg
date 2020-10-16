rem restart webby every so often
rem delay on boot
timeout 30
start /b "" \cg\cg.exe 0 do-server
:loop
   if "%time:~3,2%" == "00" (
     taskkill /f /im cg.exe
     start /b "" \cg\cg.exe 0 do-server
     timeout 3540
   ) else ( timeout 30 )
goto loop
