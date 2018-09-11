ml /c mylib.asm
ml /c showMenu.asm
ml /c writeFil.asm
ml /c showList.asm
ml /c addStu.asm
ml /c searchFi.asm
ml /c search.asm
ml /c delStu.asm
ml /c delRange.asm
ml /c main.asm
link main.obj mylib.obj showMenu.obj addStu.obj showList.obj writeFil.obj delRange.obj delStu.obj searchFi.obj search.obj
debug main.exe