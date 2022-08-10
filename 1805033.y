%{
#include<iostream>
#include<fstream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "SymbolTable.h"
#include "ScopeTable.h"
#include "SymbolInfo.h"
#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);

int error_count=0;
int line = 1;
int scope = 0;
int semantic_error = 0;
int label_count = 0; 
int temp_count = 0;

//file 
extern FILE *yyin;
FILE *input, *logout, *error;
ofstream asmCode("asmCode.asm"), optAsmCode("optAsmCode.asm");

SymbolTable table(10);


//function dec and defination check name and return type
string type_defination, type_declaration;  //type, type_final;
string name_defination, name_declaration; //name, name_final;

//variable structure
struct variable_array{
    string variable_name;
    int variable_size;  // -1 for variables
} newVariable;

vector<variable_array>list_of_Variables;

//parameter structure
struct parameter{
	string parameter_type;
	string parameter_name;
}newParameter;

//list of parameter
vector<parameter>parameter_list;


//argument list for fun call
vector<string>argument_list;


//variable and array insert in symbol table

vector<string>data_segment_list;

void insert_variable(variable_array var , string type){
	SymbolInfo* newSymbol = new SymbolInfo(var.variable_name, "ID");
	newSymbol->setReturnType(type);
	newSymbol->setArraySize(var.variable_size);

	//for asm
	string scope_number = to_string(scope);
	string name = var.variable_name;
	name = name+scope_number;//name0
	newSymbol->setAsmSymbol(name);

	

	if(var.variable_size == -1){
		name = name+ " dw ?" ;
		data_segment_list.push_back(name);

		//test
		//fprintf(asmCode, "at line %d: %s\n",  line, name.c_str());
	}else{
		//array x dw 3 dup(?)
		string size = to_string(var.variable_size);
		name = name+" dw "; //x dw
		name = name+size ; // x dw 3
		name = name+" dup(?)";// x dw 3 dup(?)
		data_segment_list.push_back(name);

		
		//fprintf(asmCode, "at line %d: %s\n",  line, name.c_str());
	}

	
	if(table.insertInTable_Symbol(newSymbol)){
		
	}else{
		
		error_count++;
		fprintf(error, "Error at line %d: Multiple declaration of '%s'\n",  line, newSymbol->getName().c_str());

	}
}

//function insert in symbol table

//new termp

string newTemp(){
	string str = "t";
	str = str + to_string(temp_count);
	temp_count++;
	return str;

}




void yyerror(const char *s)
{
	error_count++;
	fprintf(error, "Error at line %d: \"%s\" \n",  line, s);
	fprintf(logout, "Error at line %d: \"%s\" \n",  line, s);
}


%}

%define api.value.type {SymbolInfo*}

%token IF ELSE FOR WHILE
%token ID LPAREN RPAREN SEMICOLON COMMA LCURL RCURL LTHIRD RTHIRD
%token INT FLOAT VOID CONST_INT CONST_FLOAT PRINTLN RETURN
%token ASSIGNOP LOGICOP RELOP ADDOP MULOP NOT INCOP DECOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%define parse.error verbose

%start start


%%
 //start : INT ID SEMICOLON {printf("yes done ");table.insertInTable_Symbol(yylval);printf("%s\n", $2->getName().c_str());cout<<yylval->getName(); }
 start : program

	{
		//write your code in this block in all the similar blocks below
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		 fprintf(logout, "Line %d: start: program\n", line);
		 fprintf(logout,"%s \n\n",$1->getName().c_str());
	
	}
	; 

program : program unit {
		$$ = new SymbolInfo($1->getName()+" "+$2->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: program : program unit\n", line);
		fprintf(logout,"%s %s\n\n",$1->getName().c_str(), $2->getName().c_str());
}
	| unit	{
		 $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		 fprintf(logout, "Line %d: program : unit\n", line);
		 fprintf(logout,"%s \n\n",$1->getName().c_str());
	}
	;
	
unit : var_declaration	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: unit : var_declaration\n", line);
		fprintf(logout,"%s \n\n",$1->getName().c_str());
}
     | func_declaration	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: unit : func_declaration\n", line);
		fprintf(logout,"%s \n\n",$1->getName().c_str());
	 }
     | func_definition	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: unit : func_definition\n", line);
		fprintf(logout,"%s \n\n",$1->getName().c_str());
	 }
     ;
     
func_declaration : type_specifier id fun_start LPAREN parameter_list RPAREN dec_end SEMICOLON	{
		$$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$5->getName()+");", "NON_TERMINAL");
		fprintf(logout, "Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n",line);
		fprintf(logout, "%s %s (%s);\n\n",$1->getName().c_str(), $2->getName().c_str(),$5->getName().c_str() );

		//clear this parameter
		parameter_list.clear();

}
		| type_specifier id fun_start LPAREN RPAREN dec_end SEMICOLON{
		$$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+" "+");", "NON_TERMINAL");
		fprintf(logout, "Line %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n",line);
		fprintf(logout, "%s %s ( );\n\n",$1->getName().c_str(), $2->getName().c_str());

		//clear this parameter
		parameter_list.clear();
}
		;
		 
func_definition : type_specifier id fun_start LPAREN parameter_list RPAREN def_end compound_statement	{
		$$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$5->getName()+")"+$8->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n", line);
		fprintf(logout,"%s %s ( %s ) %s\n\n",$1->getName().c_str(),$2->getName().c_str(),$5->getName().c_str(),$8->getName().c_str());
}
		| type_specifier id fun_start LPAREN RPAREN def_end compound_statement	{
		$$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+")"+$7->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n", line);
		fprintf(logout,"%s %s (  ) %s\n\n",$1->getName().c_str(),$2->getName().c_str(),$7->getName().c_str());

		}
 		;				

fun_start: {
		//function is started
		
		type_declaration = type_defination;
		name_declaration = name_defination;

		//printf("decty %s, decName %s\n\n",type_declaration.c_str(),name_declaration.c_str());

}
dec_end: {
		//declaration end so table insert start
		//lookup for multiple declarations
		SymbolInfo* temp = table.lookUpTable(name_declaration);
		if(temp!=NULL){
			//already had in this scope
			semantic_error++;
			error_count++;
			fprintf(error,"Error at line %d: Function '%s' already declared\n", line,name_declaration.c_str() );
		}else{
			//so now insert
			SymbolInfo* newSymbol = new SymbolInfo(name_declaration, "ID");
			newSymbol->setReturnType(type_declaration);
			newSymbol->setArraySize(-2); //-2 for function decl
			//add param also
			for(int i=0; i<parameter_list.size(); i++) {
        		newSymbol->addParameter(parameter_list[i].parameter_type, parameter_list[i].parameter_name);
    		}
			table.insertInTable_Symbol(newSymbol);
		}
}
def_end: {
	//check already declared or not
	SymbolInfo* temp = table.lookUpTable(name_declaration);
	
		if(temp==NULL){
			//no function so add it
			SymbolInfo* newSymbol = new SymbolInfo(name_declaration, "ID");
			newSymbol->setReturnType(type_declaration);
			newSymbol->setArraySize(-3); //-3 for function defination
			//add param also
			for(int i=0; i<parameter_list.size(); i++) {
        		newSymbol->addParameter(parameter_list[i].parameter_type, parameter_list[i].parameter_name);
    		}
			table.insertInTable_Symbol(newSymbol);
		}else if(temp->getArraySize()!=-2){
			//declared not found
			semantic_error++;
			error_count++;
			fprintf(error,"Error at line %d: Function '%s' declaration not found\n", line,name_declaration.c_str() );
		}else{
				if(temp->getReturnType() != type_declaration) {
					error_count++;
					semantic_error++;
					fprintf(error,"Error at line %d: Function '%s' return type doesn't match with declaration\n", line, name_declaration.c_str());        
				} else if(temp->getParameterSize()==1 && parameter_list.size()==0 && temp->getParameter(0).parameter_type=="void") {
					temp->setArraySize(-3);
					//printf("matched\n\n");
				} else if(temp->getParameterSize()==0 && parameter_list.size()==1 && parameter_list[0].parameter_type=="void") {
							temp->setArraySize(-3);
					//printf("matched oo\n\n");
				} else if(temp->getParameterSize() != parameter_list.size()) {
					error_count++;
					semantic_error++;
					fprintf(error,"Error at line %d: Function '%s' parameter list doesn't match with declaration\n", line, name_declaration.c_str());        
				}else{
					//all param type check
					int count;
					for(count = 0 ;count <temp->getParameterSize(); count++){
						if(temp->getParameter(count).parameter_type != parameter_list[count].parameter_type){
							break;
						}
					}
					if(count == parameter_list.size()){
						//good
						temp->setArraySize(-3);
					}else{
						//bad
						error_count++;
						semantic_error++;
						fprintf(error,"Error at line %d: Function '%s' parameter types doesn't match with declaration\n", line, name_declaration.c_str());        

					}

				}
		}

}
parameter_list  : parameter_list COMMA type_specifier id	{
		$$ = new SymbolInfo($1->getName()+","+$3->getName()+" "+$4->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: parameter_list  : parameter_list COMMA type_specifier ID\n", line );
		fprintf(logout,"%s , %s %s\n\n",$1->getName().c_str(), $3->getName().c_str(), $4->getName().c_str());

		//add parameter to list
		newParameter.parameter_name = $4->getName();
		newParameter.parameter_type = $3->getName();
		parameter_list.push_back(newParameter);
}
		| parameter_list COMMA type_specifier	{
		$$ = new SymbolInfo($1->getName()+","+$3->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: parameter_list  : parameter_list COMMA type_specifier\n", line );
		fprintf(logout,"%s , %s\n\n",$1->getName().c_str(), $3->getName().c_str());

		//add parameter to list
		newParameter.parameter_name = "";
		newParameter.parameter_type = $3->getName();
		parameter_list.push_back(newParameter);
		}
 		| type_specifier id	{
		$$ = new SymbolInfo($1->getName()+ " "+$2->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: parameter_list  : type_specifier ID\n", line );
		fprintf(logout,"%s %s\n\n",$1->getName().c_str(), $2->getName().c_str());

		//add parameter to list
		newParameter.parameter_name = $2->getName();
		newParameter.parameter_type = $1->getName();
		parameter_list.push_back(newParameter);
		}
		| type_specifier	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: parameter_list  : type_specifier\n", line );
		fprintf(logout,"%s \n\n",$1->getName().c_str());

		//add parameter to list
		newParameter.parameter_name = "";
		newParameter.parameter_type = $1->getName();
		parameter_list.push_back(newParameter);
		}
 		;

 		
compound_statement : LCURL start_scope statements RCURL	{
			$$ = new SymbolInfo("{"+$3->getName()+"}", "NON_TERMINAL");
			fprintf(logout, "Line %d:compound_statement : LCURL statements RCURL \n", line);
			fprintf(logout, "{%s}\n", $3->getName().c_str());

			//new symboltable
			fprintf(logout, "\n\n");
			table.printAllScopeTable();
			fprintf(logout, "\n\n");
			table.exitScope();
}
 		    | LCURL start_scope RCURL	{
			$$ = new SymbolInfo("{}", "NON_TERMINAL");
			fprintf(logout, "Line %d:compound_statement : LCURL RCURL \n", line);
			fprintf(logout, "{ }\n");
			//new symboltable
			fprintf(logout, "\n\n");
			table.printAllScopeTable();
			fprintf(logout, "\n\n");
			table.exitScope();
			}
 		    ;
start_scope: {

			//test------------------
			// newParameter.parameter_type = "int";
			// newParameter.parameter_name = "l";
			// parameter_list.push_back(newParameter);
			//enter new scope
			table.enterScope();

			//add parameter to symbol table
			if(parameter_list.size()==1 && parameter_list[0].parameter_type == "void"){

			}else{
				for(int count = 0; count < parameter_list.size(); count++){
					newVariable.variable_name = parameter_list[count].parameter_name;
                    newVariable.variable_size = -1;
                    insert_variable(newVariable, parameter_list[count].parameter_type);
				}
			}
			parameter_list.clear();
}
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
			$$ = new SymbolInfo("", "var_declaration");


			if($1->getName() == "void"){
				//need to  check
				error_count++;
				fprintf(error, "Error at line %d: 'void' as variable type can not be used\n", line);
				
			}else{
				for(int i=0; i<list_of_Variables.size(); i++){
					//printf("%d\n\n",list_of_Variables[i].variable_size);
					insert_variable(list_of_Variables[i], $1->getName());
				}
			}

			list_of_Variables.clear();
}
 		 ;
 		 
type_specifier	: INT {
			$$ = new SymbolInfo("int", "NON_TERMINAL");
			type_defination = "int";

}
 		| FLOAT {
			$$ = new SymbolInfo("float", "NON_TERMINAL");
			type_defination = "float";
		}
 		| VOID {
			$$ = new SymbolInfo("void", "NON_TERMINAL");
			type_defination = "void";
		}
 		;
id: ID {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		name_defination = $1->getName();
} 		
declaration_list : declaration_list COMMA id {
	//variables
		$$ = new SymbolInfo("", "declaration_list");
		

		//add to list_Of_variables

		newVariable.variable_name = $3->getName();
		newVariable.variable_size = -1;//-1 for variable
		list_of_Variables.push_back(newVariable);

		SymbolInfo * temp = table.lookUpCurrent($3->getName());
		if(temp != NULL){
			error_count++;
			fprintf(error, "Error at line %d: Multiple declaration of variables '%s'\n", line,$3->getName().c_str());
			
		}

}
 		  | declaration_list COMMA id LTHIRD CONST_INT RTHIRD	{
			//for array decl
		$$ = new SymbolInfo("", "declaration_list");
		
		//add to list
		newVariable.variable_name = $3->getName();
		newVariable.variable_size = stoi($5->getName());
		list_of_Variables.push_back(newVariable);

		SymbolInfo * temp = table.lookUpCurrent($3->getName());
		if(temp != NULL){
			error_count++;
			fprintf(error, "Error at line %d: Multiple declaration of variables '%s'\n", line,$3->getName().c_str());
			
		}


		  }
 		  | id	{
			$$ = new SymbolInfo($1->getName(), "declaration_list");
			
		//add to list
		newVariable.variable_name = $1->getName();
		newVariable.variable_size = -1;
		list_of_Variables.push_back(newVariable);

		SymbolInfo * temp = table.lookUpCurrent($1->getName());
		if(temp != NULL){
			error_count++;
			fprintf(error, "Error at line %d: Multiple declaration of variables '%s'\n", line,$1->getName().c_str());
			
		}


		  }
 		  | id LTHIRD CONST_INT RTHIRD 	{
			$$ = new SymbolInfo($1->getName(), "declaration_list");
			
		//add to list
		newVariable.variable_name = $1->getName();
		newVariable.variable_size = stoi($3->getName());
		list_of_Variables.push_back(newVariable);

		SymbolInfo* temp = table.lookUpCurrent($1->getName());
		if(temp != NULL){
			error_count++;
			fprintf(error, "Error at line %d: Multiple declaration of variables %s\n", line,$1->getName().c_str());
			
		}
		  }
 		  ;
 		  
statements : statement	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statements : statement\n", line);
		fprintf(logout, "%s\n\n",$1->getName().c_str());
}
	   | statements statement	{
		$$ = new SymbolInfo($1->getName()+$2->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statements : statements statement\n", line);
		fprintf(logout, "%s %s\n\n",$1->getName().c_str(), $2->getName().c_str());
	   }
	   ;
	   
statement : var_declaration	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statement : var_declaration\n", line);
		fprintf(logout, "%s\n\n",$1->getName().c_str());
}
	  | expression_statement	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statement : expression_statement\n", line);
		fprintf(logout, "%s\n\n",$1->getName().c_str());
	  }
	  | compound_statement	{
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statement : compound_statement\n", line);
		fprintf(logout, "%s\n\n",$1->getName().c_str());
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement	{
		$$ = new SymbolInfo("\nfor("+$3->getName()+$4->getName()+$5->getName()+")"+$7->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n", line);
		fprintf(logout,"for(%s %s %s) %s\n\n",$3->getName().c_str(),$4->getName().c_str(),$5->getName().c_str(),$7->getName().c_str());

			//void function check
		if($5->getReturnType()=="void"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE	{
		$$ = new SymbolInfo("\nif("+$3->getName()+")"+$5->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statement: IF LPAREN expression RPAREN statement\n", line);
		fprintf(logout,"if(%s) %s\n\n",$3->getName().c_str(),$5->getName().c_str());

			//void function check
		if($3->getReturnType()=="void"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement	{
		$$ = new SymbolInfo("\nif("+$3->getName()+")"+$5->getName()+"else"+$7->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statement: IF LPAREN expression RPAREN statement ELSE statement\n", line);
		fprintf(logout,"if(%s) %s else %s\n\n",$3->getName().c_str(),$5->getName().c_str(), $7->getName().c_str());

			//void function check
		if($3->getReturnType()=="void"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}
	  }
	  | WHILE LPAREN expression RPAREN statement	{
		$$ = new SymbolInfo("\nwhile("+$3->getName()+")"+$5->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d:statement: WHILE LPAREN expression RPAREN statement\n", line);
		fprintf(logout,"while(%s)%s\n\n",$3->getName().c_str(),$5->getName().c_str());

		if($3->getReturnType()=="void"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON {
		$$ = new SymbolInfo("\nprintln("+$3->getName()+");", "NON_TERMINAL");
		fprintf(logout,"Line %d:statement: PRINTLN LPAREN ID RPAREN SEMICOLON\n", line);
		fprintf(logout,"println(%s);\n\n",$3->getName().c_str());

	  }
	  | RETURN expression SEMICOLON	{
		$$ = new SymbolInfo("\nreturn "+$2->getName()+";", "NON_TERMINAL");
		fprintf(logout,"Line %d:statement: RETURN expression SEMICOLON\n", line);
		fprintf(logout,"return %s;\n\n",$2->getName().c_str());

		if($2->getReturnType()=="void"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}
	  }
	  ;
	  
expression_statement 	: SEMICOLON	{
			$$ = new SymbolInfo(";", "NON_TERMINAL");
			fprintf(logout, "Line %d: expression_statement 	: SEMICOLON\n", line);
			fprintf(logout,";\n\n");
			$$->setReturnType("int");
			type_defination = "int";

}			
			| expression SEMICOLON {
			$$ = new SymbolInfo($1->getName()+";", "NON_TERMINAL");
			fprintf(logout, "Line %d: expression_statement 	: expression SEMICOLON\n", line);
			fprintf(logout,"%s;\n\n",$1->getName().c_str());
			$$->setReturnType($1->getReturnType());
			type_defination = $1->getReturnType();
			//void function check
			if($1->getReturnType()=="void"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}
			}
			;
	  
variable : id {
			$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			
			//declaration check
			SymbolInfo* temp = table.lookUpTable($1->getName());
			
			if(temp == NULL){
				error_count++;
				fprintf(error,"Error at line %d: variable '%s' not declared\n",line,$1->getName().c_str());
			} else {
				$$->setArraySize(-1);
                if(temp->getReturnType() != "void") {
                    $$->setReturnType(temp->getReturnType());
					$$->setAsmSymbol(temp->getAsmSymbol());
                } else {
                    $$->setReturnType("void");  //matching function found with return type void
                }
            }
			//variable check -1
			if(temp != NULL && temp->getArraySize()!= -1){
				error_count++;
				fprintf(error,"Error at line %d: '%s' not a variable\n",line,$1->getName().c_str());
			}

}		
	 | id LTHIRD expression RTHIRD {
		//array variables use
			$$ = new SymbolInfo("", "NON_TERMINAL");
			
			//undeclared check
			SymbolInfo* temp = table.lookUpTable($1->getName());
			if(temp==NULL){
				error_count++;
				fprintf(error,"Error at line %d: variable '%s' not declared\n",line,$1->getName().c_str());
			}else {
                if(temp->getReturnType() != "void") {
					$$->setArraySize(temp->getArraySize());
                    $$->setReturnType(temp->getReturnType());
					$$->setAsmSymbol(temp->getAsmSymbol());
                } else {
                    $$->setReturnType("void");  //matching function found with return type void
                }
            }

			//array check
			if(temp != NULL && (temp->getArraySize()== -1 || temp->getArraySize()==-2 || temp->getArraySize() == -3)){
				error_count++;
				fprintf(error,"Error at line %d: '%s' not a array\n",line,$1->getName().c_str());
			}

			//array index checking
			if($3->getReturnType()!= "int"){
				semantic_error++;
				error_count++;
				fprintf(error,"Error at line %d: array index is not int\n",line);

			}
			
			//void function check
			if($3->getReturnType()=="void"){
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}

		//code gen
		asmCode<< "\tmov bx, "+$3->getAsmSymbol()+"\n\t"+"add bx, bx"+"\n";
		cout<<"\tmov bx, "+$3->getAsmSymbol()+"\n\t"+"add bx, bx"+"\n";
		
	 }
	 ;
	 
expression : logic_expression	{
			$$ = new SymbolInfo("", "NON_TERMINAL"); 
			
			//type
			$$->setReturnType($1->getReturnType());
			type_defination = $1->getReturnType();

			$$->setAsmSymbol($1->getAsmSymbol());
			//$$->setAsmCode($1->getAsmCode());
}
	   | variable ASSIGNOP logic_expression {
		$$ = new SymbolInfo("", "NON_TERMINAL"); 
			
			//if floating point number is assigned to an integer type variable
			if($1->getReturnType()!= $3->getReturnType()){
				error_count++;
				fprintf(error, "Error at line %d: Assignment of wrong variables\n", line);
			}
			//void function call 
			if($3->getReturnType()=="void"){
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression(\n", line);
		}

			
			//type
			$$->setReturnType($1->getReturnType());
			type_defination = $1->getReturnType();

			//code genaration
			if($1->getArraySize()>-1){
				//array
			}else{
				//variable
			}
	   }	
	   ;
			
logic_expression : rel_expression {
			$$ = new SymbolInfo("", "NON_TERMINAL");
			
			//type propagation
			$$->setReturnType($1->getReturnType());
			$$->setAsmSymbol($1->getAsmSymbol());
			//$$->setAsmCode($1->getAsmCode());
}	
		 | rel_expression LOGICOP rel_expression {
			$$ = new SymbolInfo($1->getName() + $2->getName()+ $3->getName(), "NON_TERMINAL");
			

//semantic the result of RELOP and LOGICOP operation should be an integer
			$$->setReturnType("int");
			if($1->getReturnType() != "int" || $3->getReturnType() != "int"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: RELOP and LOGICOP operation should be an integer\n", line);
			}

			//code gen
		 }	
		 ;
			
rel_expression	: simple_expression {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");

			//type may be propagate to simple to rel
			$$->setReturnType($1->getReturnType());

			$$->setAsmSymbol($1->getAsmSymbol());
			//$$->setAsmCode($1->getAsmCode());
}
		| simple_expression RELOP simple_expression	{
		$$ = new SymbolInfo($1->getName() + $2->getName()+ $3->getName(), "NON_TERMINAL");
			//semantic the result of RELOP and LOGICOP operation should be an integer
			$$->setReturnType("int");
			if($1->getReturnType() != "int" || $3->getReturnType() != "int"){
				error_count++;
				fprintf(error, "Error at line %d: RELOP and LOGICOP operation should be an integer\n", line);
			}
		}
		;
				
simple_expression : term {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			
			//type may be set term to simple_expression
			$$->setReturnType($1->getReturnType());
			$$->setAsmSymbol($1->getAsmSymbol());
			//$$->setAsmCode($1->getAsmCode());
}
		  | simple_expression ADDOP term {
			$$ = new SymbolInfo($1->getName() + $2->getName()+ $3->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: simple_expressio : simple_expression ADDOP term\n", line);
			fprintf(logout, "%s %s %s\n\n",$1->getName().c_str(),$2->getName().c_str(),$3->getName().c_str());

			if($1->getReturnType()=="float" || $3->getReturnType()=="float"){
				$$->setReturnType("float");
			}else{
				$$->setReturnType("int");
			}
		  }
		  ;
					
term :	unary_expression	{
	$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: term : unary_expression\n", line);
			fprintf(logout, "%s\n\n",$1->getName().c_str() );
			//type may be set term to unary_expression
			$$->setReturnType($1->getReturnType());

}
     |  term MULOP unary_expression	{
		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: term : term MULOP unary_expression\n", line);
			fprintf(logout, "%s %s %s\n\n",$1->getName().c_str(),$2->getName().c_str(),$3->getName().c_str());
//Both the operands of the modulus operator should be integers
			if($2->getName()=="%"){
				if($1->getReturnType()!="int" || $3->getReturnType()!="int"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: Both the operands of the modulus operator should be integer\n", line);	
				}
			}
			if($2->getName()!="%"){
				if($1->getReturnType()=="float" || $3->getReturnType()=="float"){
					$$->setReturnType("float");
				}else{
					$$->setReturnType("int");
					}
			}else{
				$$->setReturnType("int");
			}
	 }
     ;

unary_expression : ADDOP unary_expression  {
			$$ = new SymbolInfo("!"+$2->getName(), "NON_TERNINAL");
			fprintf(logout, "Line %d:unary_expression : ADDOP unary_expression\n", line);
			fprintf(logout, "!%s\n\n",$1->getName().c_str(), $2->getName().c_str());
			//type propagation
			$$->setReturnType($2->getReturnType());
}
		 | NOT unary_expression {
			$$ = new SymbolInfo("!"+$2->getName(), "NON_TERNINAL");
			fprintf(logout, "Line %d:unary_expression : NOT unary_expression\n", line);
			fprintf(logout, "!%s\n\n", $2->getName().c_str());
			//type propagation
			$$->setReturnType($2->getReturnType());
		 }
		 | factor {
			$$ = new SymbolInfo($1->getName(), "NON_TERNINAL");
			fprintf(logout, "Line %d:unary_expression : factor\n", line);
			fprintf(logout, "%s\n\n", $1->getName().c_str());
			//type propagation
			$$->setReturnType($1->getReturnType());
		 }
		 ;
	
factor	: variable {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d:factor:variable\n", line);
		fprintf(logout, "%s\n\n", $1->getName().c_str());
			//type propagation
		$$->setReturnType($1->getReturnType());
}
	| id LPAREN argument_list RPAREN {
		//function call
		$$ = new SymbolInfo($1->getName()+"("+$3->getName()+")", "NON_TERMINAL");
		fprintf(logout, "Line %d:factor: ID LPAREN argument_list RPAREN\n", line);
		fprintf(logout,"%s(%s)\n\n",$1->getName().c_str(),$3->getName().c_str());
		//semantic analysis is needed
		int found_defination = 0; //1 = good 0 = not found
		int param_arg_size = 0; //1 = match 0 = not match

		//test start-----------------
/*		$1->setArraySize(-3);
		table.insertInTable_Symbol($1);
		$1->addParameter("int","a"); 	*/
		//test end-----------------
		SymbolInfo* temp = table.lookUpTable($1->getName());

		//null check
		if(temp == NULL){
			error_count++;
			semantic_error++;
			fprintf(error, "Error at line %d: no ID %s found \n",line,$1->getName().c_str());
			
		}else if(temp->getArraySize()!= -3){
			error_count++;
			semantic_error++;
			fprintf(error, "Error at line %d: no %s function defination found \n",line,$1->getName().c_str());
			

		}else{
			found_defination = 1;
		}
		//printf("%d argument_list param size %d and %s\n",argument_list.size(),temp->getParameterSize(),temp->getParameter(0).parameter_type.c_str() );

		if(found_defination==1){
			//defination found check argument with param
			if(temp->getParameterSize()==1 && argument_list.size()==0 && temp->getParameter(0).parameter_type=="void"){
				$$->setReturnType(temp->getReturnType());
				//printf("void function call\n");
			}else if(temp->getParameterSize()!= argument_list.size()){
				error_count++;
				semantic_error++;
				fprintf(error, "Error at line %d: function call with wrong arguments \n",line);
				
			}else{
				param_arg_size = 1;//check each type
			}
		}

		if(param_arg_size == 1){
			int count = 0;
			for(count = 0 ;count <temp->getParameterSize(); count++){
				if(temp->getParameter(count).parameter_type != argument_list[count]){
					break;
				}
			}
			if(count != argument_list.size()){
				error_count++;
				semantic_error++;
				fprintf(error, "Error at line %d: function call with wrong arguments type \n",line);
				
			}else{
				//all good
				$$->setReturnType(temp->getReturnType());
			}
		}
		argument_list.clear();
	}
	| LPAREN expression RPAREN	{
		$$ = new SymbolInfo("("+$2->getName()+")", "NON_TERMINAL");
		fprintf(logout,"Line %d: factor: LPAREN expression RPAREN\n",line);
		fprintf(logout,"(%s)\n\n",$2->getName().c_str());

		//void function cannot be called as a part of an expression
		if($2->getReturnType()=="void"){
			semantic_error++;
			error_count++;
			fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);

		}
		//type
		$$->setReturnType($2->getReturnType());
	}
	| CONST_INT {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: factor: CONST_INT\n",line );
		fprintf(logout,"%s\n\n",$1->getName().c_str());
		//type giving
		$$->setReturnType("int");
	}
	| CONST_FLOAT {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: factor: CONST_FLOAT\n",line );
		fprintf(logout,"%s\n\n",$1->getName().c_str());
		//type giving
		$$->setReturnType("float");
	}
	| variable INCOP {
		$$ = new SymbolInfo("", "NON_TERMINAL");
		
		//type giving
		$$->setReturnType($1->getReturnType());

		//code gen
		string temp1;
		if($1->getArraySize()>-1){
			//array
			temp1 = newTemp();
			data_segment_list.push_back(temp1+" dw ?");
			asmCode<<"\tmov ax, "+$1->getAsmSymbol()+" [bx]\n\tmov " + temp1+ ", ax\n\tinc "+$1->getAsmSymbol() + "[bx]\n";
			cout<<"\tmov ax, "+$1->getAsmSymbol()+" [bx]\n\tmov " + temp1+ ", ax\n\tinc "+$1->getAsmSymbol() + "[bx]\n";
			$$->setAsmSymbol(temp1);
		}else{
			//variable
			temp1 = newTemp();
			data_segment_list.push_back(temp1+" dw ?");
			asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tmov " + temp1+ ", ax\n\tinc "+$1->getAsmSymbol() + "\n";
			cout<<"\tmov ax, "+$1->getAsmSymbol()+"\n mov\t" + temp1+ ", ax\n\tinc "+$1->getAsmSymbol() + "\n";
			$$->setAsmSymbol(temp1);
		}
	}
	| variable DECOP {
		$$ = new SymbolInfo($1->getName()+"--", "NON_TERMINAL");
		fprintf(logout,"Line %d: factor: variable DECOP\n",line );
		fprintf(logout,"%s--\n\n",$1->getName().c_str());
		//type giving
		$$->setReturnType($1->getReturnType());
	}
	;
	
argument_list : arguments	{
			$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: argument_list : arguments\n", line);
			fprintf(logout, "%s \n\n",$1->getName().c_str());
}
			  |	{
				//dont know what to do
				$$ = new SymbolInfo("", "NON_TERMINAL");
			  }
			  ;
	
arguments : arguments COMMA logic_expression	{
			$$ = new SymbolInfo($1->getName()+","+$3->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: arguments : arguments COMMA logic_expression\n", line);
			fprintf(logout, "%s , %s\n\n",$1->getName().c_str(),$3->getName().c_str());
			//type checking for function call
			argument_list.push_back($3->getReturnType());
}
	      | logic_expression	{
			$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: arguments : logic_expression\n", line);
			fprintf(logout, "%s \n\n",$1->getName().c_str());
			//type checking for function call
			argument_list.push_back($1->getReturnType());
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{

	if((input=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logout= fopen(argv[3],"w");//logout file
	fclose(logout);
	error= fopen(argv[2],"w");//error file
	fclose(error);

	/* asmCode.open(argv[3]);//asm file
	asmCode.close();

	optAsmCode.open(argv[4]);//optasm file
	optAsmCode.close(); */

	
	logout= fopen(argv[3],"a");
	error= fopen(argv[2],"a");
	/* asmCode= fopen(argv[3],"a");
	optAsmCode= fopen(argv[4],"a"); */
	

	yyin=input;
	yyparse();
	
	//print table
	/* fprintf(logout, "\n\n");
	table.printAllScopeTable();
	fprintf(logout, "\n\n"); */

	/* fprintf(logout, "Total Line: %d\n",line);
	fprintf(logout, "Total Error: %d\n", error_count); */
	//fclose(logout);
	fclose(error);
	/* fclose(asmCode); */

	//optimizing--------------------------------
		//freopen("code.asm","r",stdin);
		//optimizeCode();
	
		//fclose(optimized_asmCode);
	
	return 0;
}

