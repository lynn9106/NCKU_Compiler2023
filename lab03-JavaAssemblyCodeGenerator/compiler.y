/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h" //Extern variables that communicate with lex
    #define YYDEBUG 1
    int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < INDENT; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    QUEUE * create_symbol(int level);
    static void insert_symbol(char *name, int mut, char *type, int addr, char *func_sig);
    SYMBOL* lookup_symbol(char *name);
    SYMBOL* lookup_symbol_NOPRINT(char *name);
    SYMBOL *find_symbol_which_table(char *name, QUEUE *queue);
    static void dump_symbol(QUEUE *queue, int tableIndex);
    static void invalid_msg(int lines, char* op);
    static void undefined_msg(int lines, char* name);
    int enqueue(QUEUE *queue, SYMBOL *element);
    void copyType(char* cpyTpye);

    /* Code generate */
    static void codegen_print();
    static void codegen_println();

    /* Global variables */
    SYMBOL* target;


    char preFunc[50] = "";
    char checktype[10] = "";
	char print_type[10] = "";
    char array_type[10] = "";

    char first_type[10] = "";
    char second_type[10] = "";

    int isFunc = 0;
    int turn = 0;
    

    /* Global variables */
    FILE *fout = NULL;
    bool HAS_ERROR = false;
    int INDENT = 0;
    int label_cnt = 0;
    bool load_ident = false;
    int ident_addr = -1;
    int assign_ident_addr = -1;
    int if_label_cnt =0;
    int while_cnt =0;
    int loop_cnt =0;
    int for_cnt = 0;
    bool funcStart = false;
    char preReturnType[5] = "";
    char ReturnType[5] = "";

    int arrIndex =0;
    int forIndex =0;
    char ForLoopElement[10] = "";
%}

// %error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token LET MUT NEWLINE
%token INT FLOAT BOOL STR
%token TRUE FALSE
%token GEQ LEQ EQL NEQ LOR LAND
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN
%token IF ELSE FOR WHILE LOOP
%token PRINT PRINTLN
%token FUNC RETURN BREAK
%token ARROW AS IN DOTDOT RSHIFT LSHIFT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT POS_INT_LIT NEG_INT_LIT
%token <f_val> FLOAT_LIT POS_FLOAT_LIT NEG_FLOAT_LIT
%token <s_val> STRING_LIT

%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> string_expression function
%type <s_val> dataType id_in_table id_name
%type <i_val> int_expression
%type <f_val> float_expression

// associative
%right '!'
%left '*' '/'
%left '+' '-'
%left '%'
%left LOR
%left LAND
%left EQL NEQ
%left '<' '>' GEQ LEQ
%left LSHIFT RSHIFT

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%
Program
    : GlobalStatementList
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : FunctionDeclStmt
    | NEWLINE
;

FunctionDeclStmt
    : FunctionDecl content
;

FunctionDecl        // func_sig default: ()
    : function '('check_parameter')' check_return      // insert(V)V, (parameter)V, (V)return, (parameter)return
    {    
          if(funcStart){
                if(strcmp(preReturnType,"V")==0)
                {
                     CODEGEN("return\n");
                }
                else if(strcmp(preReturnType,"B")==0)
                {
                     CODEGEN("ireturn\n");
                }
                else if(strcmp(preReturnType,"I")==0)
                {
                     CODEGEN("ireturn\n");
                }
                else if(strcmp(preReturnType,"S")==0)
                {
                     CODEGEN("areturn\n");
                }
                else if(strcmp(preReturnType,"F")==0)
                {
                     CODEGEN("freturn\n");
                }
                
               
                CODEGEN(".end method\n");
          }
          
          if(strcmp($1,"main")==0){
            CODEGEN(".method public static main([Ljava/lang/String;)V\n");
            CODEGEN(".limit stack 100\n");
            CODEGEN(".limit locals 100\n");
          }
          else{
            target = lookup_symbol_NOPRINT($1);
            CODEGEN(".method public static %s%s\n",target->name,target->func_sig);
            CODEGEN(".limit stack 50\n");
            CODEGEN(".limit locals 50\n");

            strcpy(preReturnType,ReturnType);
          }


          funcStart = true;
          detectsig = -1;

    }
;

check_return
    : // Empty
        {
            AddReturn(preFunc, tables[0], "");
            strcpy(ReturnType,"V");

        }
    |ARROW dataType
        {
            AddReturn(preFunc, tables[0], checktype);     // 更改func_sig中的return值
            if(strcmp(checktype,"i32")){
            strcpy(ReturnType,"I");
            }
            else if(strcmp(checktype,"f32")){
            strcpy(ReturnType,"F");
            }
            else if(strcmp(checktype,"bool")){
            strcpy(ReturnType,"B");
            }
            else if(strcmp(checktype,"str")){
            strcpy(ReturnType,"S");
            }

        }
    ;

function
    : FUNC ID
        { 
            $$ = $2;
          address = -1;						// Function Start at add= -1
          printf("func: %s\n" ,$2);			// print functionName
          insert_symbol($2, -1, "func", -1, "(");	// (name,mut,type,addr,func_sig)插入一行symbol(node)
          strcpy(preFunc, $2);
          scopeLevel++;
          currentTable = create_symbol(scopeLevel);
          isFunc = 1;
        }
;

dataType      // 定義資料類型， 存到checktype為確認error作準備
    : INT
        { 
            strcpy(array_type,"i32");
            strcpy(checktype, "i32");
        }
    | FLOAT
        { 
            strcpy(array_type,"f32");
            strcpy(checktype, "f32");
        }
    | BOOL
        {  
            strcpy(array_type,"bool");
            strcpy(checktype, "bool");
        }
    | '[' dataType ';' int_expression ']'
        {
            if(strcmp(array_type,"i32")==0){
                CODEGEN("newarray int\n");
            }
            else if(strcmp(array_type,"f32")==0){
                CODEGEN("newarray float\n");
            }
            else if(strcmp(array_type,"bool")==0){
                CODEGEN("newarray bool\n");
            }
            strcpy(checktype, "array");


    
        }
    | '&' STR
        { 
               strcpy(array_type,"str");
            strcpy(checktype, "str");
        }
;

leftBrace
    : '{'
        { 
            if(isFunc)
            {
                isFunc = 0;                 // function在判斷func時就已創建table
            }
            else
            {          
                scopeLevel++;
                currentTable = create_symbol(scopeLevel); 	}		// 在當前的scopeLevel創建symboltable(裡頭如果又有{},scopeLevel會在lex加一)

        }

;

rightBrace
    : '}'
        {  
            dump_symbol(tables[scopeLevel], scopeLevel); // 退出當前的symbol table, 並印出
        }

;

content
    : leftBrace rightBrace
    | leftBrace multi_statement rightBrace
;

check_parameter
    :
        {
            detectsig = -1;            // 沒有參數, 放V  
            AddParameter(preFunc, tables[0], checktype); 
        }
    | parameter_list
;

parameter_list       
    : parameter
    | parameter_list ',' parameter
;
parameter 
    : ID ':' dataType
    {
        insert_symbol($3,0, checktype , address, "-");
        if(detectsig == -1) detectsig =1;               // 第一個參數,串接位置為1
        AddParameter(preFunc, tables[0], checktype);   
    }
;

multi_statement 
    : multi_statement statement
    | statement
;

statement
:     print_statement ';'
    | LET let_declaration ';'
    | leftBrace multi_statement rightBrace
    | assignment_statement ';'
    | conditional_statement
    | loop_statement
    | return_statement ';' 
    | expression        // a08_function
    {
        printf("breturn\n");
    }
    | func_call ';'
    | break_statement ';'
    | NEWLINE
;

break_statement 
    : BREAK{
        CODEGEN("goto LOOPEnd_%d\n",loop_cnt);
    }
    | BREAK '"' string_expression '"'{
        CODEGEN("goto LOOPEnd_%d\n",loop_cnt);
    }
;

func_call  
    : ID '(' check_id  ')'
    {
        target = lookup_symbol($1);
        if(target != NULL){
            printf("call: %s%s\n" , target->name, target->func_sig);
                CODEGEN("invokestatic Main/%s%s\n",target->name,target->func_sig);
        } else {
            printf("error\n");
        }

 
    }
;

check_id  
    : /* empty */
    | id_list
;
id_list
    : id_in_table           // 查找已經declare過的id
    | id_list ',' id_in_table
;

return_statement
    : RETURN expression
        {
            printf("breturn\n");
            if(strcmp(checktype,"i32")==0){
                CODEGEN("ireturn\n");
            }
            else if(strcmp(checktype,"f32")==0){
                CODEGEN("freturn\n");
            }
            else if(strcmp(checktype,"str")==0){
                CODEGEN("areturn\n");
            }
            else if(strcmp(checktype,"bool")==0){
                CODEGEN("ireturn\n");
            }
        }
;

conditional_statement
    : IF expression label_if content else_label content {
    CODEGEN("end_if_label_%d:\n",if_label_cnt);
    if_label_cnt++;
    }
	| IF expression label_if content{
    CODEGEN("else_label_%d:\n",if_label_cnt);
        if_label_cnt++;
    }
    ;

else_label
:ELSE
{    CODEGEN("goto end_if_label_%d\n",if_label_cnt);
    CODEGEN("else_label_%d:\n",if_label_cnt);}
;

label_if
:
{
      CODEGEN("ifeq else_label_%d\n",if_label_cnt);
};


loop_statement
    : while_in expression while_judge content{
        CODEGEN("goto whileStart_%d\n",while_cnt);
        CODEGEN("whileEnd_%d:\n",while_cnt);
        while_cnt++;
    }
    | loop_in content{
        CODEGEN("goto LOOPStart_%d\n",loop_cnt);
        CODEGEN("LOOPEnd_%d:\n",loop_cnt);
        loop_cnt++;
    }
    | for_each multi_statement rightBrace{
            CODEGEN("iinc %d 1\n",forIndex);
            CODEGEN("goto forStart_%d\n",for_cnt);
            CODEGEN("forEnd_%d:\n",for_cnt);
            forIndex = 0;
            for_cnt++;
            strcpy(ForLoopElement,"");
    }
;  

loop_in
: LOOP{
        CODEGEN("LOOPStart_%d:\n",loop_cnt);
};

while_in
: WHILE{
    CODEGEN("whileStart_%d:\n",while_cnt);
    }
    ;
while_judge
:
{
    CODEGEN("ifeq whileEnd_%d\n",while_cnt);
}
;

for_each
    : FOR ID IN ID '{'
    {
        scopeLevel++; 

        target = lookup_symbol($4);      // 找in ID的symbol
        if(target != NULL){
            strcpy(print_type, target->type);
            printf("IDENT (name=%s, address=%d)\n" , yylval.s_val, target->address);
            currentTable = create_symbol(scopeLevel);
            insert_symbol($2, 0, target->array_type, address, "-");
        } else {
            printf("error\n");
        }

    forIndex = address+6;
    CODEGEN("arraylength\n");
    CODEGEN("istore %d\n",forIndex -1);
    CODEGEN("ldc 0\n");
    CODEGEN("istore %d\n",forIndex);
    CODEGEN("forStart_%d:\n",for_cnt);
    CODEGEN("iload %d\n",forIndex);
    CODEGEN("iload %d\n",forIndex -1);
    CODEGEN("if_icmpge forEnd_%d\n",for_cnt);
    CODEGEN("aload %d\n",target->address);
    CODEGEN("iload %d\n",forIndex);
    CODEGEN("iaload\n");
    strcpy(ForLoopElement,$2);
    }
; 

print_statement 
    : PRINT '(' expression ')'
        { 
            printf("PRINT %s\n" ,print_type);
            codegen_print(print_type);
        }
    | PRINTLN '(' expression ')'
        { 
            printf("PRINTLN %s\n" ,print_type); 
            codegen_println(print_type);

        }
;

expression
    :
    |logical_or_expression
    |func_call
    | array_access_expression
;

array_access_expression
    : ID '[' int_expression ']'  // array索引存取 
 ;   


logical_or_expression
    : logical_and_expression
    | logical_or_expression LOR logical_and_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "LOR");
            printf("LOR\n");

            CODEGEN("ior\n");
        }
;     
logical_and_expression
    : inclusive_or_expression
    | logical_and_expression LAND inclusive_or_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "LAND");
            printf("LAND\n");
            CODEGEN("iand\n");
        }
;  

inclusive_or_expression
	: and_expression
	| inclusive_or_expression '|' and_expression
;

and_expression
	: equality_expression
	| and_expression '&' equality_expression
;

equality_expression
    : relational_expression
    | equality_expression EQL relational_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "EQL");
            printf("EQL\n");
                if(strcmp(checktype,"i32")==0){
                CODEGEN("isub\n");
                CODEGEN("ifeq label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");      // false
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");           // true
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
                else if (strcmp(checktype,"f32")==0){
                CODEGEN("fcmpl\n");
                CODEGEN("ifeq label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }

        }
    | equality_expression NEQ relational_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "NEQ");
            printf("NEQ\n");
                            if(strcmp(checktype,"i32")==0){
                CODEGEN("isub\n");
                CODEGEN("ifne label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
                else if (strcmp(checktype,"f32")==0){
                CODEGEN("fcmpl\n");
                CODEGEN("ifne label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }

        }
;
relational_expression
    : shift_expression
    | relational_expression '<' shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "LSS");
                printf("LSS\n");
                if(strcmp(checktype,"i32")==0){
                CODEGEN("isub\n");
                CODEGEN("iflt label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
                else if (strcmp(checktype,"f32")==0){
                CODEGEN("fcmpl\n");
                CODEGEN("iflt label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }

        }
    | relational_expression '>' shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "GTR");
            printf("GTR\n");

                if(strcmp(checktype,"i32")==0){
                CODEGEN("isub\n");
                CODEGEN("ifgt label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
                else if (strcmp(checktype,"f32")==0){
                CODEGEN("fcmpl\n");
                CODEGEN("ifgt label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }

        }
    | relational_expression LEQ shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "LEQ");
            printf("LEQ\n");

                            if(strcmp(checktype,"i32")==0){
                CODEGEN("isub\n");
                CODEGEN("ifle label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
                else if (strcmp(checktype,"f32")==0){
                CODEGEN("fcmpl\n");
                CODEGEN("ifle label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
        }
    | relational_expression GEQ shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "GEQ");
            printf("GEQ\n");

                            if(strcmp(checktype,"i32")==0){
                CODEGEN("isub\n");
                CODEGEN("ifge label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
                else if (strcmp(checktype,"f32")==0){
                CODEGEN("fcmpl\n");
                CODEGEN("ifge label_%d\n", label_cnt++);
                CODEGEN("iconst_0\n");
                CODEGEN("goto label_%d\n", label_cnt++);
                CODEGEN("label_%d:\n", label_cnt - 2);
                CODEGEN("iconst_1\n");
                CODEGEN("label_%d:\n", label_cnt - 1);
                }
        }
;
shift_expression
	: additive_expression
	| shift_expression LSHIFT additive_expression
        { 
            if(strcmp(first_type, second_type))
                invalid_msg(yylineno, "LSHIFT");
            printf("LSHIFT\n");
        }
	| shift_expression RSHIFT additive_expression
        { 
            if(strcmp(first_type, second_type))
                invalid_msg(yylineno, "RSHIFT");
            printf("RSHIFT\n"); 
        }
additive_expression
    : multiplicative_expression
    | additive_expression '+' multiplicative_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "ADD");
            printf("ADD\n");

        if (strcmp(checktype, "f32")==0) {
                  CODEGEN("fadd\n");
        }
        else if (strcmp(checktype, "i32")==0) {
                  CODEGEN("iadd\n");
        }

        }
    | additive_expression '-' multiplicative_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "SUB");
            printf("SUB\n");


            if (strcmp(checktype, "f32")==0) {
                  CODEGEN("fsub\n");
        }
        else if (strcmp(checktype, "i32")==0) {
                  CODEGEN("isub\n");
        }
        }
;
multiplicative_expression
    : unary_expression
    | multiplicative_expression '*' unary_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "MUL");
            printf("MUL\n");

            if (strcmp(checktype, "f32")==0) {
                  CODEGEN("fmul\n");
        }
        else if (strcmp(checktype, "i32")==0) {
                  CODEGEN("imul\n");
        }
        }
    | multiplicative_expression '/' unary_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "DIV");
            printf("DIV\n");


        if (strcmp(checktype, "f32")==0) {
                  CODEGEN("fdiv\n");
        }
        else if (strcmp(checktype, "i32")==0) {
                  CODEGEN("idiv\n");
        }
        }
    | multiplicative_expression '%' unary_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "REM");
            printf("REM\n");


            if (strcmp(checktype, "i32")==0) {
                  CODEGEN("irem\n");
        }
        }
;
unary_expression
    : postfix_expression
    | '-' unary_expression
        {
            printf("NEG\n");
        }
    | '!' unary_expression
        {
            printf("NOT\n");

            CODEGEN("iconst_1\n");
            CODEGEN("ixor\n");
        }
;
postfix_expression
    : primary_expression
    | '(' expression ')'
;   
  
primary_expression
    :
      id_in_table
    | int_expression
    | float_expression
    |'"' string_expression '"'   
    | TRUE
        {
            strcpy(checktype, "bool");
            strcpy(print_type, "bool");
            printf("bool TRUE\n");

                    CODEGEN("iconst_1\n");
        }
    | FALSE
        {
            strcpy(checktype, "bool");
            strcpy(print_type, "bool");
            printf("bool FALSE\n");

                    CODEGEN("iconst_0\n");
        }
; 

int_expression    // INT
    : INT_LIT
        { 
            $$ = $1; // return 的值為INT_LIT的值
            printf("INT_LIT %d\n", $1); 
            strcpy(checktype, "i32");   
            strcpy(print_type, "i32");
            strcpy(array_type, "i32");
            copyType(checktype);
            turn++;

            CODEGEN("ldc %d\n", $1); 
        }
    | INT_LIT AS dataType
        { 
            $$ = $1; 
            copyType(checktype);
            printf("INT_LIT %d\n", $1);             // interger 2 float
            printf("i2f\n");
            turn++;

            CODEGEN("ldc %d\n", $1);
            CODEGEN("i2f\n");

        }
    // | int_expression ',' int_expression     // int array content
    //     { 
    //         $$ = $1; 
    //         strcpy(checktype, "array"); 
    //         strcpy(print_type, "array"); 
    //         strcpy(array_type, "i32");
    //     }
    // | '[' int_expression ';' int_expression ']'     // int array length
    //     { 
    //                     printf("D: \n");
    //         strcpy(checktype, "array"); 
    //         strcpy(print_type, "array");
    //     }
    | POS_INT_LIT {

            $$ = $1; // return 的值為INT_LIT的值
            printf("INT_LIT %d\n", $1); 
            strcpy(checktype, "i32");   
            strcpy(print_type, "i32");
            strcpy(array_type, "i32");
            copyType(checktype);
            turn++;

            CODEGEN("ldc %d\n", $<i_val>$);
    }
    | NEG_INT_LIT {
            $$ = $1; // return 的值為INT_LIT的值
            printf("INT_LIT %d\n", $1); 
            printf("NEG\n");
            strcpy(checktype, "i32");   
            strcpy(print_type, "i32");
            strcpy(array_type, "i32");
            copyType(checktype);
            turn++;

            CODEGEN("ldc %d\n", $<i_val>$);
    }
 
;

float_expression       // FLOAT
    : FLOAT_LIT
        { 
            $$ = $1; 
            printf("FLOAT_LIT %f\n", $1); 
            strcpy(checktype, "f32"); 
            strcpy(print_type, "f32");
            strcpy(array_type, "f32");

            CODEGEN("ldc %f\n", $1);

                                              
        }
    | FLOAT_LIT AS dataType       // float 2 int
        { 
            $$ = $1; 
            copyType(checktype);
            printf("FLOAT_LIT %f\n", $1); 
            printf("f2i\n");
            turn++;

            CODEGEN("ldc %f\n", $1);
            CODEGEN("f2i\n");

        }
    // | float_expression ',' float_expression   // float array content
    //     { 
    //         $$ = $1; 
    //         strcpy(checktype, "array"); 
    //         strcpy(print_type, "array"); 
    //         strcpy(array_type, "f32");
    //     }
    // | '[' float_expression ';' int_expression ']'     // float array length
    //     { 
    //         strcpy(checktype, "array"); 
    //         strcpy(print_type, "array");
    //     }
    | POS_FLOAT_LIT {
            $$ = $1; 
            printf("FLOAT_LIT %f\n", $1); 
            strcpy(checktype, "f32"); 
            strcpy(print_type, "f32");
            strcpy(array_type, "f32");

            CODEGEN("ldc %f\n", $<f_val>$);
    }
    | NEG_FLOAT_LIT {
            $$ = $1; 
            printf("FLOAT_LIT %f\n", $1); 
            printf("NEG\n");
            strcpy(checktype, "f32"); 
            strcpy(print_type, "f32");
            strcpy(array_type, "f32");

            CODEGEN("ldc %f\n", $<f_val>$);
    }
;

string_expression    // string
    :  STRING_LIT 
        { 
            $$ = $1; 
            printf("STRING_LIT \"%s\"\n", $1); 
            strcpy(checktype, "str"); 
            strcpy(print_type, "str"); 
            strcpy(array_type, "str");
            CODEGEN("ldc \"%s\"\n", $1);
        }
    | /* empty */
        { 
            $$ = ""; 
            printf("STRING_LIT \"\"\n"); 
            strcpy(checktype, "str"); 
            strcpy(print_type, "str"); 
            strcpy(array_type, "str");
            CODEGEN("ldc \"\"\n");
        }
;


id_in_table
    : id_name{$$=$1;}
    | ID AS dataType
    {   $$=$1;
        target = lookup_symbol($1);

        if(target != NULL){
            printf("IDENT (name=%s, address=%d)\n" , $1, target->address);
            if((strcmp(target->type, "i32") == 0) && (strcmp(checktype, "f32") == 0))
            {
                copyType("f32");
                printf("i2f\n");
                CODEGEN("i2f\n");
            } 
            else if((strcmp(target->type, "i32") == 0 )&& (strcmp(checktype, "i32") == 0)) 
            {
                copyType("i32");
                printf("i2i\n");
                CODEGEN("i2i\n");
            } 
            else if((strcmp(target->type, "f32") == 0) && (strcmp(checktype, "i32") == 0))
            {
                copyType("i32");
                printf("f2i\n");
                CODEGEN("f2i\n");
            } 
            else if((strcmp(target->type, "f32") == 0) && (strcmp(checktype, "f32") == 0))
            {
                copyType("f32");
                printf("f2f\n");
                CODEGEN("f2f\n");
            }
            strcpy(print_type, target->type);
            strcpy(array_type, target->array_type);
            turn++;


        } else {
            printf("error\n");
        
        }
    }
    | array_withID
    | '&' id_name '[' int_expression enter_DOTDOT ']'
        { 
            strcpy(checktype, "str"); strcpy(print_type, "str"); strcpy(array_type, "str");
            CODEGEN("invokevirtual java/lang/String/substring(I)Ljava/lang/String;\n");
        }
    | '&' id_name'[' int_expression enter_DOTDOT int_expression']'
        { 
            strcpy(checktype, "str"); strcpy(print_type, "str"); strcpy(array_type, "str");
            CODEGEN("invokevirtual java/lang/String/substring(II)Ljava/lang/String;\n");
        }
    | '&' id_name '[' zero_enter_DOTDOT int_expression']'
        { 
            strcpy(checktype, "str"); strcpy(print_type, "str"); strcpy(array_type, "str");
            CODEGEN("invokevirtual java/lang/String/substring(II)Ljava/lang/String;\n");

        } 
;
zero_enter_DOTDOT
:
enter_DOTDOT{
    CODEGEN("ldc 0\n");
}
;

enter_DOTDOT
    : DOTDOT
        { 
            printf("DOTDOT\n");
        }
;


id_name
    : ID
        { 
            target = lookup_symbol($1);
            if(target != NULL){
                strcpy(print_type, target->type);
                copyType(target->type);
                printf("IDENT (name=%s, address=%d)\n" , yylval.s_val, target->address);
                ident_addr = target->address;
            } 
            else {            // 無定義
                undefined_msg(yylineno + 1, $1);
                copyType("undefined");
                ident_addr = -1;
            }

            $$=$1;
            turn++;
        }
    ;

let_declaration     // LET
    : ID ':' dataType '=' expression
        { 
            insert_symbol($1, 0, checktype, address, "-");
            if (strcmp(checktype, "i32") == 0) {
                CODEGEN("istore %d\n", address - 1);
            }
            if (strcmp(checktype, "f32") == 0) {
                CODEGEN("fstore %d\n", address - 1);
            }
            if (strcmp(checktype, "str") == 0) {
                CODEGEN("astore %d\n", address - 1);
            }
            if (strcmp(checktype, "bool") == 0) {
               CODEGEN("istore %d\n", address - 1);
            }
            
        }
    | MUT ID ':' dataType '=' expression
        { 
            insert_symbol($2, 1, checktype, address, "-");
            if (strcmp(checktype, "i32") == 0) {
                CODEGEN("istore %d\n", address - 1);
            }
            if (strcmp(checktype, "f32") == 0) {
                CODEGEN("fstore %d\n", address - 1);
            }
            if (strcmp(checktype, "str") == 0) {
                CODEGEN("astore %d\n", address - 1);
            }
            if (strcmp(checktype, "bool") == 0) {
               CODEGEN("istore %d\n", address - 1);
            }
        }
    |ID ':' dataType '=' array_literal
        { 
            strcpy(checktype, "array");
            insert_symbol($1, 0, checktype, address, "-");
            CODEGEN("astore %d\n", address - 1);
            arrIndex = 0;
        }
    | MUT ID ':' dataType '=' array_literal
        { 
            strcpy(checktype, "array");
            insert_symbol($2, 1, checktype, address, "-");
            CODEGEN("astore %d\n", address - 1);
            arrIndex = 0;
        }
    | ID ':' dataType
        { 
            insert_symbol($1, 0, checktype, address, "-");
            if (strcmp(checktype, "i32") == 0) {
                CODEGEN("ldc 0\n");
                CODEGEN("istore %d\n", address - 1);
            }
            if (strcmp(checktype, "f32") == 0) {
                CODEGEN("ldc 0.000000\n");
                CODEGEN("fstore %d\n", address - 1);
            }
            if (strcmp(checktype, "str") == 0) {
                CODEGEN("ldc \"\"\n");
                CODEGEN("astore %d\n", address - 1);
            }
            if (strcmp(checktype, "bool") == 0) {
                CODEGEN("iconst_1");
                CODEGEN("istore %d\n", address - 1);
            }
        }
    | MUT ID ':' dataType
        { 
            insert_symbol($2, 1, checktype, address, "-");
            if (strcmp(checktype, "i32") == 0) {
                CODEGEN("ldc 0\n");
                CODEGEN("istore %d\n", address - 1);
            }
            if (strcmp(checktype, "f32") == 0) {
                CODEGEN("ldc 0.000000\n");
                CODEGEN("fstore %d\n", address - 1);
            }
            if (strcmp(checktype, "str") == 0) {
                CODEGEN("ldc \"\"\n");
                CODEGEN("astore %d\n", address - 1);
            }
            if (strcmp(checktype, "bool") == 0) {
                CODEGEN("iconst_1");
                CODEGEN("istore %d\n", address - 1);
            }
        }
    | ID '=' expression
        { 
            insert_symbol($1, 0, checktype, address, "-");
            if (strcmp(checktype, "i32") == 0) {
                CODEGEN("istore %d\n", address - 1);
            }
            if (strcmp(checktype, "f32") == 0) {
                CODEGEN("fstore %d\n", address - 1);
            }
            if (strcmp(checktype, "str") == 0) {
                CODEGEN("astore %d\n", address - 1);
            }
            if (strcmp(checktype, "bool") == 0) {
               CODEGEN("istore %d\n", address - 1);
            }
        }
    | MUT ID '=' expression
        { 
            insert_symbol($2, 1, checktype, address, "-");
            if (strcmp(checktype, "i32") == 0) {
                CODEGEN("istore %d\n", address - 1);
            }
            if (strcmp(checktype, "f32") == 0) {
                CODEGEN("fstore %d\n", address - 1);
            }
            if (strcmp(checktype, "str") == 0) {
                CODEGEN("astore %d\n", address - 1);
            }
            if (strcmp(checktype, "bool") == 0) {
               CODEGEN("istore %d\n", address - 1);
            }

        }
    | ID ':' dataType '=' loop_statement
    { 
        insert_symbol($1, 0, checktype, address, "-");
            if (strcmp(checktype, "i32") == 0) {
                CODEGEN("istore %d\n", address - 1);
            }
            if (strcmp(checktype, "f32") == 0) {
                CODEGEN("fstore %d\n", address - 1);
            }
            if (strcmp(checktype, "str") == 0) {
                CODEGEN("astore %d\n", address - 1);
            }
            if (strcmp(checktype, "bool") == 0) {
               CODEGEN("istore %d\n", address - 1);
            }
    }
;

array_literal
    : '[' array_elements ']'
;

array_elements
    : preload expression{
        if(strcmp(array_type,"i32")==0)  
        CODEGEN("iastore\n");
        else if(strcmp(array_type,"f32")==0)
        CODEGEN("fastore\n");
        else if(strcmp(array_type,"bool")==0)
        CODEGEN("iastore\n");
    }
    | array_elements ',' preload expression{
        if(strcmp(array_type,"i32")==0)
        CODEGEN("iastore\n");
        else if(strcmp(array_type,"f32")==0)
        CODEGEN("fastore\n");
        else if(strcmp(array_type,"bool")==0)
        CODEGEN("iastore\n");
    }
;

preload
:
{
        CODEGEN("dup\n");
        CODEGEN("iconst_%d\n",arrIndex);
        arrIndex++;
}

assignment_statement 
    : id_in_table '=' expression
        {           
            printf("ASSIGN\n");
            target = lookup_symbol_NOPRINT($1);

            ident_addr = target->address;
            assign_ident_addr = ident_addr;
            if(strcmp(checktype,"i32")==0){
            CODEGEN("istore %d\n", assign_ident_addr);
            }    
            else if(strcmp(checktype,"f32")==0){
            CODEGEN("fstore %d\n", assign_ident_addr);   
            }    
            else if(strcmp(checktype,"str")==0){
               CODEGEN("astore %d\n", assign_ident_addr);
            }
            else if(strcmp(checktype,"bool")==0){
                CODEGEN("istore %d\n", assign_ident_addr);
            }

   

        }
    | id_in_table ADD_ASSIGN expression
        { 
                printf("ADD_ASSIGN\n"); 
            target = lookup_symbol_NOPRINT($1);

            ident_addr = target->address;
            assign_ident_addr = ident_addr;

        
                    if(strcmp(checktype,"i32")==0){
                //    CODEGEN("iload %d\n", assign_ident_addr);
                //    CODEGEN("swap\n");
                    CODEGEN("iadd\n");
                    CODEGEN("istore %d\n", assign_ident_addr);
                    }
                    else if(strcmp(checktype,"f32")==0){
                //    CODEGEN("fload %d\n", assign_ident_addr);
                //    CODEGEN("swap\n");
                    CODEGEN("fadd\n");
                    CODEGEN("fstore %d\n", assign_ident_addr);
                    }

         
  
        }
    | id_in_table SUB_ASSIGN expression
        { 
                printf("SUB_ASSIGN\n");
                   target = lookup_symbol_NOPRINT($1);

            ident_addr = target->address;
            assign_ident_addr = ident_addr;
  
                

                    if(strcmp(checktype,"i32")==0){
                  //  CODEGEN("iload %d\n", assign_ident_addr);
                  //  CODEGEN("swap\n");
                    CODEGEN("isub\n");
                    CODEGEN("istore %d\n", assign_ident_addr);
                    }    
                    else if(strcmp(checktype,"f32")==0){
                 //   CODEGEN("fload %d\n", assign_ident_addr);
                 //   CODEGEN("swap\n");
                    CODEGEN("fsub\n");
                    CODEGEN("fstore %d\n", assign_ident_addr);
                    } 
                          

        }
    | id_in_table MUL_ASSIGN expression
        { 
     
                printf("MUL_ASSIGN\n");
                         target = lookup_symbol_NOPRINT($1);

            ident_addr = target->address;
            assign_ident_addr = ident_addr;              
        
                
                    if(strcmp(checktype,"i32")==0){
                //    CODEGEN("iload %d\n", assign_ident_addr);
                //    CODEGEN("swap\n");
                    CODEGEN("imul\n");
                    CODEGEN("istore %d\n", assign_ident_addr);
                    }
                    else if(strcmp(checktype,"f32")==0){
                //    CODEGEN("fload %d\n", assign_ident_addr);
                //    CODEGEN("swap\n");
                    CODEGEN("fmul\n");
                    CODEGEN("fstore %d\n", assign_ident_addr);
                    }

              

        }
    | id_in_table DIV_ASSIGN expression
        { 
 
                printf("DIV_ASSIGN\n");
                         target = lookup_symbol_NOPRINT($1);

            ident_addr = target->address;
            assign_ident_addr = ident_addr;     
             
           


                    if(strcmp(checktype,"i32")==0){
                //    CODEGEN("iload %d\n", assign_ident_addr);
                //    CODEGEN("swap\n");
                    CODEGEN("idiv\n");
                    CODEGEN("istore %d\n", assign_ident_addr);
                    }
                    else if(strcmp(checktype,"f32")==0){
               //     CODEGEN("fload %d\n", assign_ident_addr);
               //     CODEGEN("swap\n");
                    CODEGEN("fdiv\n");
                    CODEGEN("fstore %d\n", assign_ident_addr);
                    }


                    
        }
    | id_in_table REM_ASSIGN expression
        { 
  
                printf("REM_ASSIGN\n"); 
  
                    target = lookup_symbol_NOPRINT($1);

            ident_addr = target->address;
            assign_ident_addr = ident_addr;

                    if(strcmp(checktype,"i32")==0){
               //     CODEGEN("iload %d\n", assign_ident_addr);
               //     CODEGEN("swap\n");
                    CODEGEN("irem\n");
                    CODEGEN("istore %d\n", assign_ident_addr);
                    }
                    else if(strcmp(checktype,"f32")==0){
               //     CODEGEN("fload %d\n", assign_ident_addr);
               //     CODEGEN("swap\n");
                    CODEGEN("frem\n");
                    CODEGEN("fstore %d\n", assign_ident_addr);
                    }



                                            
        }
    | array_withID '=' expression
    | array_withID ADD_ASSIGN expression
    | array_withID SUB_ASSIGN expression
    | array_withID MUL_ASSIGN expression
    | array_withID DIV_ASSIGN expression
    | array_withID REM_ASSIGN expression
;

array_withID
    : ID '[' INT_LIT ']'       
        { 
            target = lookup_symbol($1);
            if(target != NULL){
                copyType(target->type);
                strcpy(print_type, target->type);
                printf("IDENT (name=%s, address=%d)\n" , $1, target->address);                
            } else {
                copyType("undefined");
                undefined_msg(yylineno + 1, $1);
            }
            printf("INT_LIT %d\n", $3); 
            strcpy(checktype, "array"); 
            strcpy(print_type, "array");

            
            CODEGEN("ldc %d\n", $3);
            CODEGEN("iaload\n");
        }
;
%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source hw3.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");

    INDENT++;

    /* Symbol table init */
    // Add your code
    scopeLevel = 0;
    address = -1;
	create_symbol(scopeLevel);		// 全域

    yylineno = 0;
    yyparse();

    /* Symbol table dump */
    // Add your code
    dump_symbol(tables[0], 0);	// 結束全域

	printf("Total lines: %d\n", yylineno);

    /* Codegen end */
    CODEGEN("return\n");
    INDENT--;
    CODEGEN(".end method\n");

    fclose(fout);
    fclose(yyin);

    if (HAS_ERROR) {
        remove(bytecode_filename);
    }
    yylex_destroy();
    return 0;
}

QUEUE * create_symbol(int level) {		// create symbol table
    printf("> Create symbol table (scope level %d)\n", level);

    QUEUE * queue = (QUEUE *)malloc(sizeof(QUEUE));
    if (queue == NULL)
    {
        fprintf(stderr, "Error: Failed to allocate memory for QUEUE\n");
        exit(EXIT_FAILURE);
    }
    queue->head = NULL;
    queue->size = 0;
    tables[scopeLevel] = queue;
    return queue;
}

static void insert_symbol(char *name, int mut, char *type, int addr, char *func_sig) {
    printf("> Insert `%s` (addr: %d) to scope level %d\n", name, addr, scopeLevel);
	SYMBOL* temp = new_symbol(name, Qsize(tables[scopeLevel]), mut, type, addr, yylineno + 1, func_sig, array_type);
    enqueue(tables[scopeLevel], temp);
    address++;
}
int enqueue(QUEUE *queue, SYMBOL *element)
{
    struct node *newNode = malloc(sizeof(struct node));
    newNode->data = element;
    newNode->next = NULL;

    if (queue->head == NULL) {
        queue->head = newNode;
    } else {
        struct node *current = queue->head;
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = newNode;
    }

    queue->size++;
    return 1;
}

SYMBOL* lookup_symbol(char *name) {
    for (int i = scopeLevel; i >= 0; i--) {
        if (tables[i] != NULL) {
            SYMBOL *symbol = find_symbol_which_table(name, tables[i]);
            if (symbol != NULL) {

                    if(strcmp(symbol->name,ForLoopElement)!=0){
                        if (strcmp(symbol->type, "i32") == 0) {
                                CODEGEN("iload %d\n", symbol->address);
                            }
                            if (strcmp(symbol->type, "f32") == 0) {
                                CODEGEN("fload %d\n", symbol->address);
                            }
                            if (strcmp(symbol->type, "str") == 0) {
                                CODEGEN("aload %d\n", symbol->address);
                            }
                            if (strcmp(symbol->type, "bool") == 0) {
                                CODEGEN("iload %d\n", symbol->address);
                            }
                            if (strcmp(symbol->type, "array") == 0) {
                                CODEGEN("aload %d\n", symbol->address);
                            }

                    }

                    return symbol;
            }
        }
    }
    return NULL;
}

SYMBOL* lookup_symbol_NOPRINT(char *name) {
    for (int i = scopeLevel; i >= 0; i--) {
        if (tables[i] != NULL) {
            SYMBOL *symbol = find_symbol_which_table(name, tables[i]);
            if (symbol != NULL) {
                    return symbol;
            }
        }
    }
    return NULL;
}

SYMBOL *find_symbol_which_table(char *name, QUEUE *queue)
{
    struct node *current = queue->head;
    while (current != NULL) {
        SYMBOL *symbol = current->data;
        if (strcmp(symbol->name, name) == 0) {
            return symbol;
        }
        current = current->next;
    }
    return NULL;
}

static void dump_symbol(QUEUE *queue, int tableIndex) {
    printf("\n> Dump symbol table (scope level: %d)\n", tableIndex);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s%-10s\n",
            "Index", "Name", "Mut","Type", "Addr", "Lineno", "Func_sig");
    struct node * symbolNode;
    SYMBOL * symbolElement;
    for(int i = 0 ;i < queue->size ;i++)
    {
        if(i==0)  {
            symbolNode = queue->head;
            symbolElement = symbolNode->data;
        }  
        printf("%-10d%-10s%-10d%-10s%-10d%-10d%-10s\n",
            i, symbolElement->name, symbolElement->mut, symbolElement->type, symbolElement->address, symbolElement->lineno, symbolElement->func_sig);
        
        if(i < (queue->size - 1))
        {symbolNode = symbolNode -> next;
        symbolElement = symbolNode->data;}
    }
    if (tableIndex != 0)
    {
     queue = NULL;
	 scopeLevel--;		// 退回上層
     }
}

static void invalid_msg(int lines, char* op)
{
      if(turn % 2 == 0)
        printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", lines+1, op, first_type, second_type);
      else
        printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", lines+1, op, second_type, first_type);
}

static void undefined_msg(int lines, char* name)
{
    printf("error:%d: undefined: %s\n", lines, name);
}

void copyType(char* cpyTpye){
    if(turn % 2 == 0){
        strcpy(first_type, cpyTpye);
    } else {
        strcpy(second_type, cpyTpye);
    }
}

/* For code generation */
void codegen_print(char* type) {
    if (strcmp(type, "i32") == 0) {
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/print(I)V\n");
    }
    if (strcmp(type, "f32") == 0) {
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/print(F)V\n");
    }
    if (strcmp(type, "str") == 0) {
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
    }
    if (strcmp(type, "bool") == 0) {
        CODEGEN("ifne label_%d\n", label_cnt++);
        CODEGEN("ldc \"false\"\n");
        CODEGEN("goto label_%d\n", label_cnt++);
        CODEGEN("label_%d:\n", label_cnt - 2);
        CODEGEN("ldc \"true\"\n");
        CODEGEN("label_%d:\n", label_cnt - 1);
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
    }
    if (strcmp(type, "array") == 0) {
        if (strcmp(array_type, "i32") == 0) {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            CODEGEN("invokevirtual java/io/PrintStream/print(I)V\n");
        }
        if (strcmp(array_type, "f32") == 0) {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            CODEGEN("invokevirtual java/io/PrintStream/print(F)V\n");
        }
    }
}

void codegen_println(char* type) {

    if (strcmp(type, "i32") == 0) {
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/println(I)V\n");
    }
    if (strcmp(type, "f32") == 0) {
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/println(F)V\n");
    }
    if (strcmp(type, "str") == 0) {
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
    }
    if (strcmp(type, "bool") == 0) {
        CODEGEN("ifne label_%d\n", label_cnt++);
        CODEGEN("ldc \"false\"\n");
        CODEGEN("goto label_%d\n", label_cnt++);
        CODEGEN("label_%d:\n", label_cnt - 2);
        CODEGEN("ldc \"true\"\n");
        CODEGEN("label_%d:\n", label_cnt - 1);
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
    }
    if (strcmp(type, "array") == 0) {
        if (strcmp(array_type, "i32") == 0) {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            CODEGEN("invokevirtual java/io/PrintStream/println(I)V\n");
        }
        if (strcmp(array_type, "f32") == 0) {
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            CODEGEN("invokevirtual java/io/PrintStream/println(F)V\n");
        }
    }
}
