# yaccFile=1805033.y
# lexFile=1805033.l
# inputFile=input.txt
# ####################################################################
# #Created by Mir Mahathir Mohammad 1605011
# ####################################################################
# DIR="$(cd "$(dirname "$0")" && pwd)"
# cd $DIR
# bison -d -y -v ./$yaccFile
# g++ -w -c -o ./y.o ./y.tab.c
# flex -o ./lex.yy.c ./$lexFile
# g++  -o ./a.out ./y.o ./l.o -lfl -ly	
# ./a.out ./input.txt

#!/bin/bash

yacc  --verbose -d -y 1805033.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 1805033.l
echo 'Generated the scanner C file'
# g++ -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ symbolInfo.cpp scopeTable.cpp symbolTable.cpp y.o l.o -lfl -o 1805033
echo 'All ready, running'
./1805033 input.c error.txt asmCode.asm optAsmCode.asm
