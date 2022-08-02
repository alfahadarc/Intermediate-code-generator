%x sngComment multiComment str
%{
#include<iostream>
#include<stdlib.h>
#include<string.h>
#include "SymbolTable.h"
#include "ScopeTable.h"
#include "SymbolInfo.h"
#include "y.tab.h"

extern FILE *error, *logout;
using namespace std;

extern YYSTYPE yylval;
extern SymbolTable table;
void yyerror(char *);

extern int error_count;
extern int line;


%}



digit [0-9]
letter [A-Za-z]
delim [ \t\r\f\v]
newline \n
ws [delim]+
id (_|{letter})(_|{letter}|{digit})*
integer {digit}+
number {digit}*(\.{digit}+)?(E[+-]?{digit}+)?
ADDOP [+-] 
MULOP [*/%]

%%

{delim}+	{}
{newline} {line++;}

"if"	{return IF;}
"for"	{return FOR;}
"do"	{return DO;}
"int"	{return INT;}		
"float"	{return FLOAT;}
"void"	{return VOID;}				
"else"	{return ELSE;}
"while"	{return WHILE;}
"char"	{return CHAR;}
"double"	{return DOUBLE;}
"return"	{return RETURN;}
"println"	{return PRINTLN;}

{ADDOP} { 
			SymbolInfo *s= new  SymbolInfo(yytext, (char *)"ADDOP");
			yylval = (YYSTYPE)s;
			return ADDOP;
		}



{MULOP}	{
			SymbolInfo *s= new  SymbolInfo(yytext, (char *)"MULOP");
			yylval = (YYSTYPE)s;
			return MULOP;
		}


"=" 	{return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		SymbolInfo *s= new  SymbolInfo(yytext, (char *)"RELOP");
		yylval = (YYSTYPE)s;
		return RELOP;
	}

"&&"	|
"||"	{
			SymbolInfo *s= new  SymbolInfo(yytext, (char *)"LOGICOP");
			yylval = (YYSTYPE)s;
			return LOGICOP;
		}
"!"		{	return NOT; }


";" 	{ return SEMICOLON;}
"," 	{return COMMA;}
"(" 	{return LPAREN;}
")" 	{return RPAREN;}
"{" 	{return LCURL;}
"}" 	{return RCURL;}
"[" 	{return LTHIRD;}
"]" 	{return RTHIRD;}
"++" 	{return INCOP;}
"--" 	{return DECOP;}



{integer}	{
				SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_INT");
				yylval = (YYSTYPE)s;
				return CONST_INT;
			}
{number} 	{	
				SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_FLOAT");
				yylval = (YYSTYPE)s;
				return CONST_FLOAT; 
			}
{id} 		{	 
				
				SymbolInfo *s= table.lookUpTable(yytext);
				if(s==NULL)
				{					
					s= new SymbolInfo(yytext, (char *)"ID");
				}
				yylval = (YYSTYPE)s;
							
				return ID;
			}

\/\/  	{
			BEGIN(sngComment);
		}

<sngComment>\\\n {
			line++;
		}
<sngComment>\n {
			line++;
			BEGIN(INITIAL);
		}

<sngComment>([\t !-~]{-}[\\\n])+|\\[^\n] {
	}
\/\*	{
		BEGIN(multiComment);
}
<multiComment>\n {
			line++;
		}
<multiComment>\*\/ {
			BEGIN(INITIAL);
		}
<multiComment>([\t !-~]{-}[\*])+|(\*[^\/])+ {
    }
<multiComment><<EOF>> {
			error_count++;
			fprintf(error,"Line no %d: Unfinished comment\n",line);
			BEGIN(INITIAL);
}
%%

int yywrap(void)
{
	return 1;
}






