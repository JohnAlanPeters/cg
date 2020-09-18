rem _makenewcg.bat
chdir "c:\cg\src"
timeout 1
\cg\win32for.exe fload cg.f
start /b \cg\cg.exe
