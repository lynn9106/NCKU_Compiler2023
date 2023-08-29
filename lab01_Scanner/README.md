# Scanner
*Compiler 2023 Programming Assignment I  
Lexical Definition*  
  
**a scanner for the μRust language with lex**  


## Environment
For Linux  
>Ubuntu 20.04 LTS

Install Dependencies
>`sudo apt install flex bison git python3 python3-pip`
>>local judge:
`pip3 install local-judge`

## Example of Your Scanner Output
* Input  
```lex=
fn main() { // Your first μrust program  
    println("Hello World!");   
    /* Hello   
    World */ /*  
    */  
}
```
* Ouput  
```
fn       	 FUNC
main     	 IDENT
(        	 LPAREN
)        	 RPAREN
{        	 LBRACE
// Your first μrust program 	 COMMENT
         	 NEWLINE
println 	 PRINTLN
(        	 LPAREN
"        	 QUOTA
Hello World! 	 STRING_LIT
"        	 QUOTA
)        	 RPAREN
;        	 SEMICOLON
         	 NEWLINE
/* Hello 
    World */       	 MUTI_LINE_COMMENT
/*
    */       	 MUTI_LINE_COMMENT
         	 NEWLINE
}        	 RBRACE

Finish scanning,
total line: 6
comment line: 4
```
## Get Started
* Compile source code and execute with input file  
`$make clean && make  
$ ./myscanner < input/a01_arithmetic.rs >| tmp.out`  
* Compare with the ground truth   
`$diff -y tmp.out answer/a01_arithmetic.out`  
* Check the output file char-by-char  
`$od -c answer/a01_arithmetic.out`  
