%{
#include<iostream>
#include<fstream>
#include <sstream>
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
bool name_main;

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
vector<string>list_of_local; //func arguments
vector<string>list_of_temp; //function call arguments

string insert_variable(variable_array var , string type){
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

	return name;
}

//function insert in symbol table

//new termp

string newTemp(){
	string str = "t";
	str = str + to_string(temp_count);
	temp_count++;
	return str;

}

string newLabel(){
	string str = "L";
	str = str + to_string(label_count);
	label_count++;
	return str;
}


void yyerror(const char *s)
{
	error_count++;
	fprintf(error, "Error at line %d: \"%s\" \n",  line, s);
	fprintf(logout, "Error at line %d: \"%s\" \n",  line, s);
	cout<<"Error at line "<<line<< " : "<<s<<endl;
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
 start :{

	//start asm
	asmCode<<".model small\n.stack 100h\n.data\n\n";
	

	asmCode<<"\n.code\n\n";

 } program

	{
		//write your code in this block in all the similar blocks below
		 fprintf(logout, "Line %d: start: program\n", line);
		 
		

		 //println

		asmCode<<";println function\n";
		 asmCode<<"\nprintln proc\n";
		 asmCode<<"\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n\tpush bp\n\n"; //push regi
		 asmCode<<"\tmov bp, sp\n\tmov ax, [bp+12]\n";
		
		asmCode<<"\n;negative check\n";
		string poslabel = newLabel();
		asmCode<<"\tcmp ax, 0\n";
		asmCode<<"\tjge "+poslabel+"\n";

		//negative
		asmCode<<"\tpush ax\n";
		asmCode<<"\tmov dl, '-'\n";
		asmCode<<"\tmov ah, 2\n\tint 21h\n";
		asmCode<<"\tpop ax\n\tneg ax\n";

		//digits loop
		asmCode<<"\t"+poslabel+":\n";
		asmCode<<"\tmov cx, 0\n\tmov bx, 10D\n";

		string looplabel= newLabel();
		asmCode<<"\t"+looplabel+":\n";
		asmCode<<"\t\tmov dx, 0\n";
		asmCode<<"\t\tdiv bx\n";
		asmCode<<"\t\tpush dx\n";
		asmCode<<"\t\tinc cx\n";
		asmCode<<"\t\tcmp ax, 0\n";
		asmCode<<"\t\tjne "+looplabel+"\n";

		asmCode<<"\n;printing\n";
		asmCode<<"\tmov ah, 2\n";
		string label = newLabel();
		asmCode<<"\t"+label+":\n";
		asmCode<<"\t\tpop dx\n";
		asmCode<<"\t\tadd dl, '0'\n";
		asmCode<<"\t\tint 21h\n\t\tloop "+label+"\n";
		asmCode<<"\tmov dl, 20h\n\tint 21h\n";

		//new line
// 		CR EQU 0DH
// LF EQU 0AH
// 		MOV AH, 2
//     MOV DL, 0DH
//     INT 21H
//     MOV DL, 0AH
//     INT 21H
//     RET

		asmCode<<"\tmov ah, 2\n\tmov dl, 0dh\n\tint 21h\n\tmov dl, 0ah\n\tint 21h\n";

		//regi back
		asmCode<<"\n\tpop bp\n\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\n"; //pop regi
		asmCode<<"\tret\nprintln endp\n";
		asmCode<<"end main\n";
		
		//save all data segment var
		for(int i = 0; i < data_segment_list.size(); i++ ){
			asmCode<<"\t"+data_segment_list[i]+"\n";
		}
		data_segment_list.clear();

	
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
		 
func_definition : type_specifier id fun_start LPAREN parameter_list RPAREN {
		//data segment
		//main
		int paramSize = parameter_list.size();
		int var = 2+(2*paramSize);
		if($2->getName()=="main"){
			name_main = true;
			//cout<<"haha with param";
			asmCode<<"\n;main start\n\n";
			asmCode<<"main proc\n\tmov ax, @data\n\tmov ds, ax\n\n";
		}else{
			asmCode<<"\n;function start\n\n";

			asmCode<<$2->getName()+ " proc\n\n"; //fun proc
			asmCode<<"\tpush bp\n";  // push bp
			asmCode<<"\tmov bp, sp\n"; // bp = sp
			asmCode<< "\tadd bp, "+ to_string(var) +" \n";
		}

} def_end compound_statement	{

	if($2->getName()=="main"){
			asmCode<<"\n;DOS EXIT\n";
			asmCode<<"\n\n\tmov ah, 4ch\n\tint 21h\nmain endp\n\n";
	}else{
		
		asmCode<<"\tpop bp\n";
		asmCode<<"\tret\n";
		asmCode<<$2->getName()+ " endp\n\t";
	}
		

// ;DOS EXIT
//     MOV AH, 4CH
//     INT 21H

// MAIN ENDP
// END MAIN

}
		| type_specifier id fun_start LPAREN RPAREN {
			if($2->getName()=="main"){
				name_main = true;
				//cout<<"haha without param";
				asmCode<<"\n;main start\n\n";
				asmCode<<"main proc\n\tmov ax, @data\n\tmov ds, ax\n\n";
			}else{
				asmCode<<"\n;function start\n\n";

				asmCode<<$2->getName()+ " proc\n\n"; //fun proc
				asmCode<<"\tpush bp\n";  // push bp
				
			}
		} def_end compound_statement	{
			if($2->getName()=="main"){
				asmCode<<"\n;DOS EXIT\n\n";
				asmCode<<"\n\n\tmov ah, 4ch\n\tint 21h\nmain endp\n\n";
			}else{
				
				asmCode<<"\tpop bp\n";
				asmCode<<"\tret\n";
				asmCode<<$2->getName()+ " endp\n\t";
			}
		


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
			//cout<<"\n line: "+to_string(line)+" "+to_string(newSymbol->getArraySize())+" "+newSymbol->getName();
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

			
			table.exitScope();
}
 		    | LCURL start_scope RCURL	{
			$$ = new SymbolInfo("{}", "NON_TERMINAL");
			fprintf(logout, "Line %d:compound_statement : LCURL RCURL \n", line);
			fprintf(logout, "{ }\n");
			
			table.exitScope();
			}
 		    ;
start_scope: {

			
			table.enterScope();
			scope++;

			//add parameter to symbol table
			if(parameter_list.size()==1 && parameter_list[0].parameter_type == "void"){

			}else{
				for(int count = 0; count < parameter_list.size(); count++){
					//newVariable.variable_name = parameter_list[count].parameter_name;
                    //newVariable.variable_size = -1;
                    
				//insert_variable(newVariable, parameter_list[count].parameter_type);
				SymbolInfo* newSymbol = new SymbolInfo(parameter_list[count].parameter_name, parameter_list[count].parameter_type);
				newSymbol->setReturnType(parameter_list[count].parameter_type);
				newSymbol->setArraySize(-1);
				string val = to_string(-2*count)+"[bp]";
				newSymbol->setAsmSymbol(val);
				//cout<<"\n param inseert \n";
				//cout<<newSymbol->getName()+ " " + newSymbol->getType() + " " + newSymbol->getAsmSymbol()+ " \n";
				table.insertInTable_Symbol(newSymbol);
				}
			}
			parameter_list.clear();
}
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
			$$ = new SymbolInfo("", "var_declaration");

			string none;

			if($1->getName() == "void"){
				//need to  check
				error_count++;
				fprintf(error, "Error at line %d: 'void' as variable type can not be used\n", line);
				
			}else{
				for(int i=0; i<list_of_Variables.size(); i++){
					//printf("%d\n\n",list_of_Variables[i].variable_size);
					none = insert_variable(list_of_Variables[i], $1->getName());
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
	  | FOR LPAREN expression_statement embeded_expression {

		/* 
			init
		l1:
			cond - true - l2
			flase - jmp l4
		l3:
			inc
			jmp l1
		l2:
			stmt
			jmp l3
		l4:
				$5
		*/
		string label1= newLabel();
		string label2 = newLabel();
		string label3 = newLabel();
		string label4 = newLabel();

		string labels = label1+" "+label2+" "+label3+" "+label4;
		$$ = new SymbolInfo(labels, "non");

		asmCode<<label1+":\n";
	  } expression_statement embeded_expression {
		stringstream ss($5->getName());
		string label1,label2 ,label3,label4 ;
		ss>>label1;
		ss>>label2;
		ss>>label3;
		ss>>label4;

		//\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)
		asmCode<<"\tmov ax,  " + $6->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+label4+"\n\tjmp "+label2+"\n";
		asmCode<<label3+":\n";
	  } expression embeded_expression RPAREN {
		stringstream ss($5->getName());
		string label1,label2 ,label3,label4 ;
		ss>>label1;
		ss>>label2;
		ss>>label3;
		ss>>label4;
		asmCode<< "\tjmp "+label1+"\n";
		asmCode<<label2+":\n";
	  } statement	{
		stringstream ss($5->getName());
		string label1,label2 ,label3,label4 ;
		ss>>label1;
		ss>>label2;
		ss>>label3;
		ss>>label4;
		asmCode<< "\tjmp "+label3+"\n";
		asmCode<<label4+":\n";

		$$ = new SymbolInfo("\nfor("+$3->getName()+$5->getName()+$7->getName()+")"+$10->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d: statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n", line);
		fprintf(logout,"for(%s %s %s) %s\n\n",$3->getName().c_str(),$5->getName().c_str(),$7->getName().c_str(),$10->getName().c_str());

			//void function check
		if($5->getReturnType()=="void"){
				semantic_error++;
				error_count++;
				fprintf(error, "Error at line %d: void function cannot be called as a part of an expression\n", line);
		}

		
	  }
	  | condition_rule %prec LOWER_THAN_ELSE	{
		$$ = new SymbolInfo("", "NON_TERMINAL");
		fprintf(logout, "Line %d: statement: IF LPAREN expression RPAREN statement\n", line);
		
		//label in $1->getName()
		
		asmCode<< $1->getName()+":\n";
		asmCode<<"\n;if then end\n\n";
		
		}
	  | condition_rule ELSE {
		string label1 = newLabel();
		asmCode<<"\tjmp "+label1+"\n";
		asmCode<< $1->getName()+":\n";
		$$ = new SymbolInfo(label1, "label");
	  } statement	{
		fprintf(logout, "Line %d: statement: IF LPAREN expression RPAREN statement ELSE statement\n", line);
		
		asmCode<< $3->getName()+":\n";
		asmCode<<"\n;if then else end\n\n";
		
	  }
	  | WHILE LPAREN {
		string while_start = newLabel();
		string while_end = newLabel();
		asmCode<<while_start+":\n";

		//send label
		$$ = new SymbolInfo(while_start, while_end);
	  } expression {
		string while_end = $3->getType();
		asmCode<<"\tmov ax, "+$4->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+while_end+"\n";

	  } RPAREN statement	{
		string while_start = $3->getName();
		string while_end = $3->getType();
		asmCode<<"\tjmp "+while_start+"\n";
		asmCode<<while_end+":\n";

	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON {
		$$ = new SymbolInfo("\nprintln("+$3->getName()+");", "NON_TERMINAL");
		fprintf(logout,"Line %d:statement: PRINTLN LPAREN ID RPAREN SEMICOLON\n", line);
		fprintf(logout,"println(%s);\n\n",$3->getName().c_str());

		//code
		SymbolInfo* temp = table.lookUpTable($3->getName());
		string asmVar;
		if(temp == NULL){
			error_count++;
			fprintf(error,"Error at line %d: variable '%s' not declared\n",line,$1->getName().c_str());
			asmVar = "";
		} else{
			if(temp->getReturnType() != "void") {
                    asmVar = temp->getAsmSymbol();
                } else {
                    asmVar = "";  // no id 
                }
		}
		
		// if((temp!=NULL) && (temp->getArraySize()!=-1)) { 
		// 	cout<<"na dhuki nai";
		// 	//found but not variable
		// 	error_count++;
        //         fprintf(error,"Error at line %d: mismatch \n",line);

        //         asmVar = "";  // no id available
        //     }

		//asm code
		
		asmCode<<"\n ;before push asmvar for println\n";
		asmCode<<"\tpush "+asmVar+"\n\tcall println\n";



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

		if(name_main){
			//cout<<"hi";
			//asmCode<<"\n;DOS EXIT\n";
			//asmCode<<"\n\n\tmov ah, 4ch\n\tint 21h\nmain endp\n\n";
		}else{
			asmCode<<"\tmov ax, "+$2->getAsmSymbol()+"\n";
			asmCode<<"\tmov 2[bp], ax\n";
			asmCode<<"\tpop bp\n";
			asmCode<<"\tret\n";
		}
		//code
		
		asmCode<<"\n;RETURN expression SEMICOLON\n\n";

	  }
	  ;
condition_rule: IF LPAREN expression RPAREN {
	string label = newLabel();
	$$ = new SymbolInfo(label, "label");
	//code
	asmCode<<"\tmov ax, "+$3->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+label+"\n";
} statement{
	$$ = $5;

}

embeded_expression: {
	type_declaration = type_defination;
}
	  
expression_statement 	: SEMICOLON	{
			$$ = new SymbolInfo(";", "NON_TERMINAL");
			fprintf(logout, "Line %d: expression_statement 	: SEMICOLON\n", line);
			fprintf(logout,";\n\n");
			$$->setReturnType("int");
			type_defination = "int";
			//code
			$$->setAsmSymbol(";");

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
		//code 
			$$->setAsmSymbol($1->getAsmSymbol());
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
					//cout<<$$->getArraySize();
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
		//cout<<"\tmov bx, "+$3->getAsmSymbol()+"\n\t"+"add bx, bx"+"\n";
		
	 }
	 ;
	 
expression : logic_expression	{
			$$ = new SymbolInfo("", "NON_TERMINAL"); 
			
			//type
			$$->setReturnType($1->getReturnType());
			type_defination = $1->getReturnType();

			$$->setAsmSymbol($1->getAsmSymbol());
			//$$->setAsmCode($1->getAsmCode());
			//cout<<"\n exp " + $1->getAsmSymbol() + "\n";
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
			asmCode<<"\n;variable ASSIGNOP logic_expression\n\n";
			//cout<< to_string(line)+" ask :" + $3->getAsmSymbol();
			if($1->getArraySize()>-1){
			
				string temp = newTemp();
				data_segment_list.push_back(temp+" dw ?");
				
				asmCode<<"\tmov ax, "+$3->getAsmSymbol()+"\n";
				asmCode<<"\tmov "+$1->getAsmSymbol()+"[bx], ax\n\tmov "+temp+", ax\n";

				
				$$->setAsmSymbol(temp);
		}else{
				//variable
				
				asmCode<<"\tmov ax, "+$3->getAsmSymbol()+"\n\tmov "+$1->getAsmSymbol()+", ax\n";
                $$->setAsmSymbol($1->getAsmSymbol());
			}
			asmCode<<"\n;variable ASSIGNOP logic_expression\n\n";
	   }	
	   ;
			
logic_expression : rel_expression {
			$$ = new SymbolInfo("", "NON_TERMINAL");
			
			//type propagation
			$$->setReturnType($1->getReturnType());
			$$->setAsmSymbol($1->getAsmSymbol());
			
			
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
			string label1 = newLabel();
            string label2 = newLabel();
            string temp = newTemp();
            data_segment_list.push_back(temp+" dw ?");

            
            if($2->getName() == "&&") {
				asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+label1+"\n";
				asmCode<<"\tmov ax, "+$3->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+label1+"\n";
				asmCode<<"\tmov ax, 1\n\tmov "+temp+", ax\n\tjmp "+label2+"\n\t";
				asmCode<<label1+":\n\tmov ax, 0\n\tmov "+temp+", ax\n\t"+label2+":\n";

				cout<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+label1+"\n";
				cout<<"\tmov ax, "+$3->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+label1+"\n";
				cout<<"\tmov ax, 1\n\tmov "+temp+", ax\n\tjmp "+label2+"\n\t";
				cout<<label1+":\n\tmov ax, 0\n\tmov "+temp+", ax\n\t"+label2+":\n";

            } else {
                //  "||" 

				asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tcmp ax, 0\n\tjne "+label1+"\n";
				asmCode<<"\tmov ax, "+$3->getAsmSymbol()+"\n\tcmp ax, 0\n\tjne "+label1+"\n";
				asmCode<<"\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n\t";
				asmCode<<label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";
				
				cout<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tcmp ax, 0\n\tjne "+label1+"\n";
				cout<<"\tmov ax, "+$3->getAsmSymbol()+"\n\tcmp ax, 0\n\tjne "+label1+"\n";
				cout<<"\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n\t";
				cout<<label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";

            }
            
            $$->setAsmSymbol(temp);
		 }	
		 ;
			
rel_expression	: simple_expression {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");

			//type may be propagate to simple to rel
			$$->setReturnType($1->getReturnType());
			$$->setAsmSymbol($1->getAsmSymbol());
			
}
		| simple_expression RELOP simple_expression	{
		$$ = new SymbolInfo($1->getName() + $2->getName()+ $3->getName(), "NON_TERMINAL");
			//semantic the result of RELOP and LOGICOP operation should be an integer
			$$->setReturnType("int");
			if($1->getReturnType() != "int" || $3->getReturnType() != "int"){
				error_count++;
				fprintf(error, "Error at line %d: RELOP and LOGICOP operation should be an integer\n", line);
			}

		/* symbol and code setting */
            string label1 = newLabel();
            string label2 = newLabel();
            string temp = newTemp();
            data_segment_list.push_back(temp+" dw ?");

            asmCode<<"\n;relational exp\n";
			asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tcmp ax, "+$3->getAsmSymbol()+"\n";

            if($2->getName() == "<") {
				asmCode<<"\n;relational exp <\n";

				asmCode<<"\tjl "+label1+"\n\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n";
                asmCode<<"\t"+label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";


            } else if($2->getName() == "<=") {
				asmCode<<"\n;relational exp <=\n";
				asmCode<<"\tjle "+label1+"\n\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n";
                asmCode<<"\t"+label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";
				               

			
            } else if($2->getName() == ">") {
				asmCode<<"\n;relational exp >\n";
				asmCode<<"\tjg "+label1+"\n\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n";
                asmCode<<"\t"+label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";

			} else if($2->getName() == ">=") {
				asmCode<<"\n;relational exp >=\n";
				asmCode<<"\tjge "+label1+"\n\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n";
                asmCode<<"\t"+label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";
  
			} else if($2->getName() == "==") {
				asmCode<<"\n;relational exp ==\n";
				asmCode<<"\tje "+label1+"\n\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n";
                asmCode<<"\t"+label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";

              
			} else {
				// !=
				asmCode<<"\n;relational exp !=\n";
				asmCode<<"\tjne "+label1+"\n\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n";
                asmCode<<"\t"+label1+":\n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";

                          }

            $$->setAsmSymbol(temp);
			asmCode<<"\n;relational exp end\n";
		}
		;
				
simple_expression : term {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			
			//type may be set term to simple_expression
			$$->setReturnType($1->getReturnType());
			$$->setAsmSymbol($1->getAsmSymbol());
			
			
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

			string temp = newTemp();
            data_segment_list.push_back(temp+" dw ?");
			//code
			if($2->getName() == "+") {
                /*addition */
				asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tadd ax, "+$3->getAsmSymbol()+"\n\tmov "+temp+", ax\n";
				cout<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tadd ax, "+$3->getAsmSymbol()+"\n\tmov "+temp+", ax\n";
                $$->setAsmSymbol(temp);

            } else {
                /* ubtraction */
				asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tsub ax, "+$3->getAsmSymbol()+"\n\tmov "+temp+", ax\n";
              $$->setAsmSymbol(temp);
            }
		  }
		  ;
					
term :	unary_expression	{
	$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: term : unary_expression\n", line);
			fprintf(logout, "%s\n\n",$1->getName().c_str() );
			//type may be set term to unary_expression
			$$->setReturnType($1->getReturnType());
			$$->setAsmSymbol($1->getAsmSymbol());
			

}
     |  term MULOP unary_expression	{
		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: term : term MULOP unary_expression\n", line);
			fprintf(logout, "%s %s %s\n\n",$1->getName().c_str(),$2->getName().c_str(),$3->getName().c_str());
//Both the operands of the modulus operator should be integers
			if($2->getName()=="%"){
				if($1->getReturnType()!="int" || $3->getReturnType()!="int"){
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

			//code
			string temp = newTemp();
            data_segment_list.push_back(temp+" dw ?");
			if($2->getName() == "*"){
				//mul
				asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tmov bx, "+$3->getAsmSymbol()+"\n\timul bx\n\tmov "+temp+", ax\n";
			$$->setAsmSymbol(temp);
			}else{
				// div mod
				asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tcwd\n";
                asmCode<<"\tmov bx, "+$3->getAsmSymbol()+"\n\tidiv bx\n";

				
                
                if($2->getName() == "/") {
					asmCode<<"\tmov "+temp+", ax\n";
					
                    
                } else {
					asmCode<<"\tmov "+temp+", dx\n";
					
                    
                }
                
                $$->setAsmSymbol(temp);
			}
	 }
     ;

unary_expression : ADDOP unary_expression  {
			$$ = new SymbolInfo("!"+$2->getName(), "NON_TERNINAL");
			fprintf(logout, "Line %d:unary_expression : ADDOP unary_expression\n", line);
			fprintf(logout, "!%s\n\n",$1->getName().c_str(), $2->getName().c_str());
			//type propagation
			$$->setReturnType($2->getReturnType());
			//code if neg
			if($1->getName() == "-"){
				string temp = newTemp();
				data_segment_list.push_back(temp+" dw ?");

				asmCode<<"\tmov ax, "+$2->getAsmSymbol()+"\n\tmov "+temp+", ax\n\tneg " + temp+"\n";
	$$->setAsmSymbol(temp);
			}else{
				$$->setAsmSymbol($2->getAsmSymbol());
			}
}
		 | NOT unary_expression {
			$$ = new SymbolInfo("!"+$2->getName(), "NON_TERNINAL");
			fprintf(logout, "Line %d:unary_expression : NOT unary_expression\n", line);
			fprintf(logout, "!%s\n\n", $2->getName().c_str());
			//type propagation
			$$->setReturnType("int");
			//code
			string label1 = newLabel();
            string label2 = newLabel();
            string temp = newTemp();
            data_segment_list.push_back(temp+" dw ?");

			asmCode<<"\tmov ax, "+$2->getAsmSymbol()+"\n\tcmp ax, 0\n\tje "+label1+"\n\tmov ax, 0\n\tmov "+temp+", ax\n\tjmp "+label2+"\n";
			asmCode<<"\t"+label1+": \n\tmov ax, 1\n\tmov "+temp+", ax\n\t"+label2+":\n";
            
   $$->setAsmSymbol(temp);
		 }
		 | factor {
			$$ = new SymbolInfo($1->getName(), "NON_TERNINAL");
			fprintf(logout, "Line %d:unary_expression : factor\n", line);
			fprintf(logout, "%s\n\n", $1->getName().c_str());
			//type propagation
			$$->setReturnType($1->getReturnType());
			$$->setAsmSymbol($1->getAsmSymbol());
			
		 }
		 ;
	
factor	: variable {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout, "Line %d:factor	: variable\n", line);
			fprintf(logout, "%s\n\n", $1->getName().c_str());
			//type propagation
		$$->setReturnType($1->getReturnType());
		$$->setArraySize($1->getArraySize());
		$$->setAsmSymbol($1->getAsmSymbol());
		//cout<<$$->getArraySize();
		if($$->getArraySize()>-1){
			
			string temp = newTemp();
			data_segment_list.push_back(temp+" dw ?");
			asmCode<<"\tmov ax, "+ $1->getAsmSymbol()+"[bx]\n\tmov "+temp+", ax\n";
			
			$$->setAsmSymbol(temp);
		}

}
	| id LPAREN argument_list RPAREN {
		//function call
		$$ = new SymbolInfo($1->getName()+"("+$3->getName()+")", "NON_TERMINAL");
		fprintf(logout, "Line %d:factor: ID LPAREN argument_list RPAREN\n", line);
		fprintf(logout,"%s(%s)\n\n",$1->getName().c_str(),$3->getName().c_str());
		//semantic analysis is needed
		int found_defination = 0; //1 = good 0 = not found
		int param_arg_size = 0; //1 = match 0 = not match

		bool allGood = false;
		SymbolInfo* temp = table.lookUpTable($1->getName());

		//null check
		if(temp == NULL){
			error_count++;
			fprintf(error, "Error at line %d: no ID %s found \n",line,$1->getName().c_str());
			
		}else if(temp->getArraySize()!= -3){
			error_count++;
			fprintf(error, "Error at line %d: no %s function defination found \n",line,$1->getName().c_str());
			

		}else{
			found_defination = 1;
		}
		//printf("%d argument_list param size %d and %s\n",argument_list.size(),temp->getParameterSize(),temp->getParameter(0).parameter_type.c_str() );

		if(found_defination==1){
			//defination found check argument with param
			if(temp->getParameterSize()==1 && argument_list.size()==0 && temp->getParameter(0).parameter_type=="void"){
				$$->setReturnType(temp->getReturnType());
				//good
				allGood = true;
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
				//good
				allGood = true;
			}
		}

		if(allGood){


			//ret-ar1-ar2-arg3
			asmCode<<"\tpush 1\n";
			for(int count =0; count < list_of_temp.size(); count++){
				asmCode<<"\tpush "+list_of_temp[count] + " \n";
				//cout<<list_of_temp[count];
			}

			asmCode<<"\tcall "+$1->getName()+"\n";

			//string garbage = newTemp();
			//data_segment_list.push_back(garbage+" dw ?");
			for(int count = list_of_temp.size()-1; count >= 0; count--){
				asmCode<<"\tpop ax \n";
			}
			string tempVar = newTemp();
			data_segment_list.push_back(tempVar+" dw ?");
			asmCode<<"\tpop "+tempVar+"\n";
			$$->setAsmSymbol(tempVar);

			
		}
		
		argument_list.clear();
		list_of_temp.clear();
	}
	| LPAREN expression RPAREN	{
		$$ = new SymbolInfo("", "NON_TERMINAL");
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
		$$->setAsmSymbol($2->getAsmSymbol());
	}
	| CONST_INT {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: factor: CONST_INT\n",line );
		fprintf(logout,"%s\n\n",$1->getName().c_str());
		//type giving
		$$->setReturnType("int");
		//code
		$$->setAsmSymbol($1->getName());
	}
	| CONST_FLOAT {
		$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
		fprintf(logout,"Line %d: factor: CONST_FLOAT\n",line );
		fprintf(logout,"%s\n\n",$1->getName().c_str());
		//type giving
		$$->setReturnType("float");
		//code
		$$->setAsmSymbol($1->getName());
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
			asmCode<<"\n\t;variable INCOP\n\n";
$$->setAsmSymbol(temp1);
		}else{
			//variable
			temp1 = newTemp();
			data_segment_list.push_back(temp1+" dw ?");
			asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tmov " + temp1+ ", ax\n\tinc "+$1->getAsmSymbol() + "\n";
			asmCode<<"\n\t;variable INCOP\n\n";
						$$->setAsmSymbol(temp1);
		}
	}
	| variable DECOP {
		$$ = new SymbolInfo("", "NON_TERMINAL");
		
		//type giving
		$$->setReturnType($1->getReturnType());
		//code gen
		string temp1;
		if($1->getArraySize()>-1){
			//array
			temp1 = newTemp();
			data_segment_list.push_back(temp1+" dw ?");
			asmCode<<"\tmov ax, "+$1->getAsmSymbol()+" [bx]\n\tmov " + temp1+ ", ax\n\tdec "+$1->getAsmSymbol() + "[bx]\n";
			asmCode<<"\n\t;variable DECOP\n\n";
			
			$$->setAsmSymbol(temp1);
		}else{
			//variable
			temp1 = newTemp();
			data_segment_list.push_back(temp1+" dw ?");
			asmCode<<"\tmov ax, "+$1->getAsmSymbol()+"\n\tmov " + temp1+ ", ax\n\tdec "+$1->getAsmSymbol() + "\n";
			asmCode<<"\n\t;variable DECOP\n\n";
			
			$$->setAsmSymbol(temp1);
		}
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

			//temp list
			list_of_temp.push_back($3->getAsmSymbol());
}
	      | logic_expression	{
			$$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
			fprintf(logout, "Line %d: arguments : logic_expression\n", line);
			fprintf(logout, "%s \n\n",$1->getName().c_str());
			//type checking for function call
			argument_list.push_back($1->getReturnType());
			//temp list
			list_of_temp.push_back($1->getAsmSymbol());
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


	

	
	logout= fopen(argv[3],"a");
	error= fopen(argv[2],"a");
	
	

	yyin=input;
	yyparse();
	
	
	fclose(error);
	if(error_count > 0){
		
		asmCode<<"error in code\n";
	}

	//optimizing--------------------------------
		//freopen("code.asm","r",stdin);
		//optimizeCode();
	
		//fclose(optimized_asmCode);
	
	return 0;
}

