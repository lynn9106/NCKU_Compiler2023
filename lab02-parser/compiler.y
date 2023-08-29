/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h" // Extern variables that communicate with lex
    #define YYDEBUG 1
    int yydebug = 1;

    extern int yylineno;
    extern int yylex(); // call to invoke lexer, returns token
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    QUEUE * create_symbol(int level);
    static void insert_symbol(char *name, int mut, char *type, int addr, char *func_sig);
    SYMBOL* lookup_symbol(char *name);
    SYMBOL *find_symbol_which_table(char *name, QUEUE *queue);
    static void dump_symbol(QUEUE *queue, int tableIndex);
    static void invalid_msg(int lines, char* op);
    static void undefined_msg(int lines, char* name);
    int enqueue(QUEUE *queue, SYMBOL *element);
    void copyType(char* cpyTpye);
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
%}


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
// %token ID ARROW AS IN DOTDOT RSHIFT LSHIFT
%token ARROW AS IN DOTDOT RSHIFT LSHIFT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <s_val> STRING_LIT
%token <f_val> FLOAT_LIT

%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> string_expression
%type <s_val> dataType
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
;

check_return
    : // Empty
        {
            AddReturn(preFunc, tables[0], "");
        }
    |ARROW dataType
        {
            AddReturn(preFunc, tables[0], checktype);     // 更改func_sig中的return值
        }
    ;

function
    : FUNC ID
        { 
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
            strcpy(checktype, "i32");
        }
    | FLOAT
        { 
            strcpy(checktype, "f32");
        }
    | BOOL
        { 
            strcpy(checktype, "bool");
        }
    | '[' dataType ';' int_expression ']'
        {   strcpy(checktype, "array");
        }
    | '&' STR
        { 
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
    : BREAK
    | BREAK '"' string_expression '"'
;

func_call  
    : ID '(' check_id  ')'
    {
        target = lookup_symbol($1);
        if(target != NULL){
            printf("call: %s%s\n" , target->name, target->func_sig);
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
        }
;

conditional_statement
    : IF expression content
	| IF expression content ELSE content
    ;

loop_statement
    : WHILE expression content
    | LOOP content
    | for_each multi_statement rightBrace
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
    }
;  

print_statement 
    : PRINT '(' expression ')'
        { 
            printf("PRINT %s\n" ,print_type);
        }
    | PRINTLN '(' expression ')'
        { 
            printf("PRINTLN %s\n" ,print_type); 
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
        }
;     
logical_and_expression
    : inclusive_or_expression
    | logical_and_expression LAND inclusive_or_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "LAND");
            printf("LAND\n");
        }
;  
inclusive_or_expression
	: and_expression
	| inclusive_or_expression '|' and_expression
and_expression
	: equality_expression
	| and_expression '&' equality_expression
equality_expression
    : relational_expression
    | equality_expression EQL relational_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "EQL");
            printf("EQL\n");
        }
    | equality_expression NEQ relational_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "NEQ");
            printf("NEQ\n");
        }
;
relational_expression
    : shift_expression
    | relational_expression '<' shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "LSS");
            printf("LSS\n");
        }
    | relational_expression '>' shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "GTR");
            printf("GTR\n");
        }
    | relational_expression LEQ shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "LEQ");
            printf("LEQ\n");
        }
    | relational_expression GEQ shift_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "GEQ");
            printf("GEQ\n");
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
        }
    | additive_expression '-' multiplicative_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "SUB");
            printf("SUB\n");
        }
;
multiplicative_expression
    : unary_expression
    | multiplicative_expression '*' unary_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "MUL");
            printf("MUL\n");
        }
    | multiplicative_expression '/' unary_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "DIV");
            printf("DIV\n");
        }
    | multiplicative_expression '%' unary_expression
        {
            if (strcmp(first_type, second_type))
                invalid_msg(yylineno, "REM");
            printf("REM\n");
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
        }
    | FALSE
        {
            strcpy(checktype, "bool");
            strcpy(print_type, "bool");
            printf("bool FALSE\n");
        }
; 

int_expression    // INT
    : INT_LIT
        { 
            $$ = $1; // return 的值為INT_LIT的值
            printf("INT_LIT %d\n", $1); 
            strcpy(checktype, "i32");   
            strcpy(print_type, "i32");
            copyType(checktype);
            turn++;
        }
    | INT_LIT AS dataType
        { 
            $$ = $1; 
            copyType(checktype);
            printf("INT_LIT %d\n", $1);             // interger 2 float
            printf("i2f\n");
            turn++;
        }
    | int_expression ',' int_expression     // int array content
        { 
            $$ = $1; 
            strcpy(checktype, "array"); 
            strcpy(print_type, "array"); 
            strcpy(array_type, "i32");
        }
    | '[' int_expression ';' int_expression ']'     // int array length
        { 
                        printf("D: \n");
            strcpy(checktype, "array"); 
            strcpy(print_type, "array");
        }
 
;

float_expression       // FLOAT
    : FLOAT_LIT
        { 
            $$ = $1; 
            printf("FLOAT_LIT %f\n", $1); 
            strcpy(checktype, "f32"); 
            strcpy(print_type, "f32");
        }
    | FLOAT_LIT AS dataType       // float 2 int
        { 
            $$ = $1; 
            copyType(checktype);
            printf("FLOAT_LIT %f\n", $1); 
            printf("f2i\n");
            turn++;
        }
    | float_expression ',' float_expression   // float array content
        { 
            $$ = $1; 
            strcpy(checktype, "array"); 
            strcpy(print_type, "array"); 
            strcpy(array_type, "f32");
        }
    | '[' float_expression ';' int_expression ']'     // float array length
        { 
            strcpy(checktype, "array"); 
            strcpy(print_type, "array");
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
        }
    | /* empty */
        { 
            $$ = ""; 
            printf("STRING_LIT \"\"\n"); 
            strcpy(checktype, "str"); 
            strcpy(print_type, "str"); 
            strcpy(array_type, "str");
        }
;


id_in_table
    : id_name
    | ID AS dataType
    {
        target = lookup_symbol(yylval.s_val);
        if(target != NULL){
            printf("IDENT (name=%s, address=%d)\n" , yylval.s_val, target->address);
            if((strcmp(target->type, "i32") == 0) && (strcmp(checktype, "f32") == 0))
            {
                copyType("f32");
                printf("i2f\n");
            } 
            else if((strcmp(target->type, "i32") == 0 )&& (strcmp(checktype, "i32") == 0)) 
            {
                copyType("i32");
                printf("i2i\n");
            } 
            else if((strcmp(target->type, "f32") == 0) && (strcmp(checktype, "i32") == 0))
            {
                copyType("i32");
                printf("f2i\n");
            } 
            else if((strcmp(target->type, "f32") == 0) && (strcmp(checktype, "f32") == 0))
            {
                copyType("f32");
                printf("f2f\n");
            }
            strcpy(print_type, target->type);
            turn++;

        } else {
            printf("error\n");
        
        }
    }
    | array_withID
    | '&' id_name '[' int_expression enter_DOTDOT ']'
        { 
            strcpy(checktype, "str"); strcpy(print_type, "str"); strcpy(array_type, "str");
        }
    | '&' id_name'[' int_expression enter_DOTDOT int_expression']'
        { 
            strcpy(checktype, "str"); strcpy(print_type, "str"); strcpy(array_type, "str");
        }
    | '&' id_name '[' enter_DOTDOT int_expression']'
        { 
            strcpy(checktype, "str"); strcpy(print_type, "str"); strcpy(array_type, "str");
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
                
            } 
            else {            // 無定義
                undefined_msg(yylineno + 1, $1);
                copyType("undefined");
            }
            turn++;
        }
    ;

let_declaration     // LET
    : ID ':' dataType '=' expression
        { 
            insert_symbol($1, 0, checktype, address, "-");
        }
    | MUT ID ':' dataType '=' expression
        { 
            insert_symbol($2, 1, checktype, address, "-");
        }
    |ID ':' dataType '=' array_literal
        { 
            insert_symbol($1, 0, checktype, address, "-");
        }
    | MUT ID ':' dataType '=' array_literal
        { 
            insert_symbol($2, 1, checktype, address, "-");
        }
    | ID ':' dataType
        { 
            insert_symbol($1, 0, checktype, address, "-");
        }
    | MUT ID ':' dataType
        { 
            insert_symbol($2, 1, checktype, address, "-");
        }
    | ID '=' expression
        { 
            insert_symbol($1, 0, checktype, address, "-");
        }
    | MUT ID '=' expression
        { 
            insert_symbol($2, 1, checktype, address, "-");

        }
    | ID ':' dataType '=' loop_statement
    { 
        insert_symbol($1, 0, checktype, address, "-");
    }
;

array_literal
    : '[' array_elements ']'
;

array_elements
    : expression
    | array_elements ',' expression
;

assignment_statement 
    : ID '=' expression
        {           
            target = lookup_symbol($1);
            if(target != NULL){
                printf("ASSIGN\n");
            } else {
                undefined_msg(yylineno + 1, $1);
            }
        }
    | ID ADD_ASSIGN expression
        { 
            printf("ADD_ASSIGN\n"); 
        }
    | ID SUB_ASSIGN expression
        { 
            printf("SUB_ASSIGN\n"); 
        }
    | ID MUL_ASSIGN expression
        { 
            printf("MUL_ASSIGN\n"); 
        }
    | ID DIV_ASSIGN expression
        { 
            printf("DIV_ASSIGN\n"); 
        }
    | ID REM_ASSIGN expression
        { 
            printf("REM_ASSIGN\n"); 
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

    yylineno = 0;
    scopeLevel = 0;
    address = -1;
	create_symbol(scopeLevel);		// 全域

    yyparse();

	dump_symbol(tables[0], 0);	// 結束全域
	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
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
