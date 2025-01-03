%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
//#include<../src/tree.h>
#include "tree.h"
#include<../src/strtab.h>

extern int yylineno;
/* nodeTypes refer to different types of internal and external nodes that can be part of the abstract syntax tree.*/

/* NOTE: mC has two kinds of scopes for variables : local and global. Variables declared outside any
function are considered globals, whereas variables (and parameters) declared inside a function foo are local to foo. You should update the scope variable whenever you are inside a production that matches function definition (funDecl production). The rationale is that you are entering that function, so all variables, arrays, and other functions should be within this scope. You should pass this variable whenever you are calling the ST_insert or ST_lookup functions. This variable should be updated to scope = "" to indicate global scope whenever funDecl finishes. Treat these hints as helpful directions only. You may implement all of the functions as you like and not adhere to my instructions. As long as the directory structure is correct and the file names are correct, we are okay with it. */
char* scope = "";
%}

/* the union describes the fields available in the yylval variable */
%union
{
    int value;
    struct treenode *node;
    char *strval;
}

/*Add token declarations below. The type <value> indicates that the associated token will be of a value type such as integer, float etc., and <strval> indicates that the associated token will be of string type.*/
%token <strval> ID
%token <value> INTCONST
/* TODO: Add the rest of the tokens below.*/

%token <value> KWD_IF KWD_ELSE KWD_WHILE KWD_INT KWD_CHAR KWD_RETURN KWD_VOID
%token <value> OPER_ADD OPER_SUB OPER_MUL OPER_DIV OPER_LTE OPER_GTE OPER_LT OPER_GT OPER_EQ OPER_NEQ OPER_ASGN
%token <value> LSQ_BRKT RSQ_BRKT LCRLY_BRKT RCRLY_BRKT LPAREN RPAREN COMMA SEMICLN
%token <value> ERROR CHARCONST STRCONST ILLEGAL_TOKEN


/* TODO: Declate non-terminal symbols as of type node. Provided below is one example. node is defined as 'struct treenode *node' in the above union data structure. This declaration indicates to parser that these non-terminal variables will be implemented using a 'treenode *' type data structure. Hence, the circles you draw when drawing a parse tree, the following lines are telling yacc that these will eventually become circles in an AST. This is one of the connections between the AST you draw by hand and how yacc implements code to concretize that. We provide with two examples: program and declList from the grammar. Make sure to add the rest.  */

%type <node> program declList decl varDecl typeSpecifier funDecl formalDeclList formalDecl funBody localDeclList
%type <node> statementList statement compoundStmt assignStmt condStmt loopStmt returnStmt
%type <node> var expression relop addExpr addop term mulop factor funcCallExpr argList
%type <node> funcTypeName


%start program

%%
/* TODO: Your grammar and semantic actions go here. We provide with two example productions and their associated code for adding non-terminals to the AST.*/

program         : declList    
                 {
                    char* name = (char*)malloc(6 * sizeof(char));
                    strcpy(name,"output");
                    int index = ST_insert(name, scope, VOID_TYPE, FUNCTION);
                    tree* progNode = maketree(PROGRAM);
                    addChild(progNode, $1);
                    ast = progNode;
                 }
                ;

declList        : decl
                 {
                    tree* declListNode = maketree(DECLLIST);
                    addChild(declListNode, $1);
                    $$ = declListNode;
                 }
                | declList decl
                 {
                    tree* declListNode = maketree(DECLLIST);
                    flattenList(declListNode, $1);
                    addChild(declListNode, $2);
                    $$ = declListNode;
                 }
                ;


decl            : varDecl
                 {
                    /* tree* declNode = maketree(DECL);
                    addChild(declNode, $1);
                    $$ = declNode; */
                    $$ = $1;
                 }
                | funDecl
                 {
                    /* tree* declNode = maketree(DECL);
                    addChild(declNode, $1);
                    $$ = declNode; */
                    $$ = $1;
                 }
                ;

varDecl     : typeSpecifier ID SEMICLN
              {
		            printf("%s\n", $2);
		            tree *declNode = maketree(VARDECL);
                  addChild(declNode, $1);
                  int index = ST_insert($2, scope, $1->val, SCALAR);
                  addChild(declNode, maketreeWithVal(IDENTIFIER, index));   //insert identifier into table  (the index, ex in parser)
		            $$ = declNode;
	            }
              | typeSpecifier ID LSQ_BRKT INTCONST RSQ_BRKT SEMICLN
                {
                  printf("%s\n", $2);
                  tree *arrayDeclNode = maketree(ARRAYDECL);
                  addChild(arrayDeclNode, $1);
                  int index = ST_insert($2, scope, $1->val, ARRAY);
                  addChild(arrayDeclNode, maketreeWithVal(IDENTIFIER, index));   //insert identifier into table
                  addChild(arrayDeclNode, maketreeWithVal(INTEGER, $4));      //insert identifier into table
                  $$ = arrayDeclNode;
                }
            ;  
             
typeSpecifier   : KWD_INT
                 {
                    $$ = maketreeWithVal(TYPESPEC, INT_TYPE);

                 }
                | KWD_CHAR
                 {
                    $$ = maketreeWithVal(TYPESPEC, CHAR_TYPE);
                 }
                | KWD_VOID
                 {
                    $$ = maketreeWithVal(TYPESPEC, VOID_TYPE);
                 }
                ;

funDecl         : funcTypeName LPAREN formalDeclList RPAREN funBody
                 {
                    tree* funDeclNode = maketree(FUNDECL);
                    addChild(funDeclNode, $1);
                    addChild(funDeclNode, $3);
                    addChild(funDeclNode, $5);
                    $$ = funDeclNode;
                    scope = "";
                 }
                | funcTypeName LPAREN RPAREN funBody
                 {
                    tree* funDeclNode = maketree(FUNDECL);
                    addChild(funDeclNode, $1);
                    addChild(funDeclNode, $4);
                    $$ = funDeclNode;
                    scope = "";
                 }
                ;

funcTypeName    : typeSpecifier ID
                 {
                    // Separate the function name in order to set the scope for other symbols.
                    tree* funcTypeNameNode = maketree(FUNCTYPENAME);
                    addChild(funcTypeNameNode, $1);
                    int index = ST_insert($2, scope, $1->val, FUNCTION);
                    addChild(funcTypeNameNode, maketreeWithVal(IDENTIFIER, index));
                    $$ = funcTypeNameNode;
                    scope = $2;
                 }
                ;

formalDeclList  : formalDecl
                 {
                    tree* formalDeclListNode = maketree(FORMALDECLLIST);
                    addChild(formalDeclListNode, $1);
                    $$ = formalDeclListNode;
                 }
                | formalDeclList COMMA formalDecl
                 {
                    tree* formalDeclListNode = maketree(FORMALDECLLIST);
                    addChild(formalDeclListNode, $1);
                    addChild(formalDeclListNode, $3);
                    $$ = formalDeclListNode;
                 }
                ;

formalDecl      : typeSpecifier ID
                 {
                    tree* formalDeclNode = maketree(FORMALDECL);
                    addChild(formalDeclNode, $1);
                    int index = ST_insert($2, scope, $1->val, SCALAR);
                    tree* idNode = maketreeWithVal(IDENTIFIER, index);
                    addChild(formalDeclNode, idNode);
                    $$ = formalDeclNode;
                 }
                | typeSpecifier ID LSQ_BRKT RSQ_BRKT
                 {
                    tree* formalDeclNode = maketree(FORMALDECL);
                    addChild(formalDeclNode, $1);
                    int index = ST_insert($2, scope, $1->val, ARRAY);
                    tree* idNode = maketreeWithVal(IDENTIFIER, index);
                    addChild(formalDeclNode, idNode);
                    $$ = formalDeclNode;
                 }
                ;

funBody         : LCRLY_BRKT localDeclList statementList RCRLY_BRKT
                 {
                    tree* funBodyNode = maketree(FUNBODY);
                    if($2 != NULL){
                     addChild(funBodyNode, $2);
                    }
                    if($3 != NULL){
                     addChild(funBodyNode, $3);
                    }
                    $$ = funBodyNode;
                 }
                ;

localDeclList   :
                 {
                    $$ = NULL;

                 }     
                | varDecl localDeclList
                 {
                    tree* localDecList = maketree(LOCALDECLLIST);   //create node
                    addChild(localDecList, $1);                     // add children
                    if($2 != NULL){
                     addChild(localDecList, $2);
                    }
                    $$ = localDecList;                              // return value
                 }
                ;

statementList   :
	 	           {
                    $$ = NULL;
                 }
                | statement statementList
                 {
                    tree* statementList = maketree(STATEMENTLIST);
                    addChild(statementList, $1);
                    if($2 != NULL){
                     flattenList(statementList, $2);
                    }
                    $$ = statementList;                              //correct to here     // make them return stuff  , $$ =
                 }
                ;                                                   

statement       : compoundStmt
                {
                  tree* StmtNode = maketree(STATEMENT);
                  addChild(StmtNode, $1);
                  $$ = StmtNode;
                }
                | assignStmt      
                {
                  tree* StmtNode = maketree(STATEMENT);
                  addChild(StmtNode, $1);
                  $$ = StmtNode;
                }
                | condStmt
                {
                  tree* StmtNode = maketree(STATEMENT);
                  addChild(StmtNode, $1);
                  $$ = StmtNode;
                }
                | loopStmt
                {
                  tree* StmtNode = maketree(STATEMENT);
                  addChild(StmtNode, $1);
                  $$ = StmtNode;
                }
                | returnStmt
                {
                  tree* StmtNode = maketree(STATEMENT);
                  addChild(StmtNode, $1);
                  $$ = StmtNode;
                }
                ;

compoundStmt    : LCRLY_BRKT statementList RCRLY_BRKT
		          {
		            tree* compoundStmtNode = maketree(COMPOUNDSTMT);
                  addChild(compoundStmtNode, $2);
                  $$ = compoundStmtNode;
		          }	
                ;

assignStmt      : var OPER_ASGN expression SEMICLN
                {
		            tree *assignNode = maketree(ASSIGNSTMT);
		            addChild(assignNode, $1);
                  addChild(assignNode, $3);
		            $$ = assignNode;
	             }
                | expression SEMICLN
                {
                  tree *assignNode = maketree(ASSIGNSTMT);
		            addChild(assignNode, $1);
		            $$ = assignNode;
                }
                ;

condStmt        : KWD_IF LPAREN expression RPAREN statement
		          {
                  tree* condStmtNode = maketree(CONDSTMT);
                  addChild(condStmtNode, $3);
                  addChild(condStmtNode, $5);
                  $$ = condStmtNode;
                } 
                | KWD_IF LPAREN expression RPAREN statement KWD_ELSE statement
		          {
                  tree* condStmtNode = maketree(CONDSTMT);
                  addChild(condStmtNode, $3);
                  addChild(condStmtNode, $5);
                  addChild(condStmtNode, $7);
                  $$ = condStmtNode;
                }
                ;

loopStmt        : KWD_WHILE LPAREN expression RPAREN statement
		          {
                  tree* loopStmtNode = maketree(LOOPSTMT);
                  addChild(loopStmtNode, $3);
                  addChild(loopStmtNode, $5);
                  $$ = loopStmtNode;
                }
                ;

returnStmt      : KWD_RETURN SEMICLN
		          {
                  tree* returnStmtNode = maketree(RETURNSTMT);
                  $$ = returnStmtNode;
                }
                | KWD_RETURN expression SEMICLN
		          {
                  tree* returnStmtNode = maketree(RETURNSTMT);
                  addChild(returnStmtNode, $2);
                  $$ = returnStmtNode;
                }
                ;

var             : ID
		             {
                     int index = ST_lookup($1, scope);
                    $$ = maketreeWithVal(IDENTIFIER, index);
                   }
                | ID LSQ_BRKT expression RSQ_BRKT
		             {
                    tree* varNode = maketree(VARIABLE);
                    int index = ST_lookup($1, scope);
                    addChild(varNode, maketreeWithVal(IDENTIFIER,index));
                    addChild(varNode, $3);
                    $$ = varNode;
                   }
                ;

expression      : addExpr
                 {
                  tree* exprNode = maketree(EXPRESSION);
                  addChild(exprNode, $1);
                  $$ = exprNode;
                 }
                | expression relop addExpr
                 {
                  tree* exprNode = maketree(EXPRESSION);
                  addChild(exprNode, $1);
                  addChild(exprNode, $2);
                  addChild(exprNode, $3);
                  $$ = exprNode;
                 }
                ;

relop           : OPER_LTE
                 {
                    $$ = maketreeWithVal(RELOP, LTE);
                 }
                | OPER_LT
                 {
                    $$ = maketreeWithVal(RELOP, LT);
                 }
                | OPER_GT
                 {
                    $$ = maketreeWithVal(RELOP, GT);
                 }
                | OPER_GTE
                 {
                    $$ = maketreeWithVal(RELOP, GTE);
                 }
                | OPER_EQ
                 {
                    $$ = maketreeWithVal(RELOP, EQ);
                 }
                | OPER_NEQ
                 {
                    $$ = maketreeWithVal(RELOP, NEQ);
                 }
                ;

addExpr         : term
                 {
                  tree* addExprNode = maketree(ADDEXPR);
                  addChild(addExprNode, $1);
                  $$ = addExprNode;
                 }
                | addExpr addop term
                 {
                  tree* addExprNode = maketree(ADDEXPR);
                  addChild(addExprNode, $1);
                  addChild(addExprNode, $2);
                  addChild(addExprNode, $3);
                  $$ = addExprNode;
                 }
                ;

addop           : OPER_ADD
                 {
                    $$ = maketreeWithVal(ADDOP, ADD);
                 }
                | OPER_SUB
                 {
                    $$ = maketreeWithVal(ADDOP, SUB);
                 }
                ;

term            : factor
                 {
                  tree* termNode = maketree(TERM);
                  addChild(termNode, $1);
                  $$ = termNode;
                 }
                | term mulop factor
                 {
                  tree* termNode = maketree(TERM);
                  addChild(termNode, $1);
                  addChild(termNode, $2);
                  addChild(termNode, $3);
                  $$ = termNode;
                 }
                ;

mulop           : OPER_MUL
                 {
                    $$ = maketreeWithVal(MULOP, MUL);
                 }
                | OPER_DIV
                 {
                    $$ = maketreeWithVal(MULOP, DIV);
                 }
                ;

factor          : LPAREN expression RPAREN
                 {
                     tree* factorNode = maketree(FACTOR);
                     addChild(factorNode, $2);
                     $$ = factorNode;
                 }
                | var
                 {
                     tree* factorNode = maketree(FACTOR);
                     addChild(factorNode, $1);
                     $$ = factorNode;
                 }
                | funcCallExpr
                 {
                     tree* factorNode = maketree(FACTOR);
                     addChild(factorNode, $1);
                     $$ = factorNode;
                 }
                | INTCONST
                 {
                     tree* factorNode = maketree(FACTOR);
                     tree* intNode = maketreeWithVal(INTEGER, $1);
                     addChild(factorNode, intNode);
                     $$ = factorNode;
                 }
                | CHARCONST
                 {
                     tree* factorNode = maketree(FACTOR);
                     tree* charNode = maketreeWithVal(CHAR, $1);
                     addChild(factorNode, charNode);
                     $$ = factorNode;
                 }
                ;

funcCallExpr    : ID LPAREN argList RPAREN
                 {
                    tree* funcCallNode = maketree(FUNCCALLEXPR);
                    int index = ST_lookup($1, scope);
                    addChild(funcCallNode, maketreeWithVal(IDENTIFIER, index));
                    addChild(funcCallNode, $3); // Arguments
                    $$ = funcCallNode;
                 }
                | ID LPAREN RPAREN
                 {
                    tree* funcCallNode = maketree(FUNCCALLEXPR);
                    int index = ST_lookup($1, scope);
                    addChild(funcCallNode, maketreeWithVal(IDENTIFIER, index));
                    $$ = funcCallNode; // No arguments
                 }
                ;

argList         : expression
                 {
                  tree* argListNode = maketree(ARGLIST);
                  addChild(argListNode, $1);
                  $$ = argListNode;
                 }
                | argList COMMA expression
                 {
                  tree* argListNode = maketree(ARGLIST);
                  addChild(argListNode, $1);
                  addChild(argListNode, $3);
                  $$ = argListNode;
                 }
                ;



%%

int yywarning(char * msg){
    printf("warning: line %d: %s\n", yylineno, msg);
    return 0;
}

int yyerror(char * msg){
    printf("error: line %d: %s\n", yylineno, msg);
    return 0;
}
