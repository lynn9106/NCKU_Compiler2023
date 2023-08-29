# Parser
*Compiler 2023 Programming Assignment II
Syntactic and Semantic Definitions for μRust*  
  
**a parser for the μRust language that supports print IO, arithmetic operations and some basic constructs for μRust**  


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
fn main() {
    let height:i32 = 99;
    {
        let width: f32 = 3.14;
    } // A. Exit... dump scope level 2
    let length: f32 = 0.0;
    { 
        let length: &str = "hello world";
        { 
            let length: bool = true;
        } // B. Exit... dump scope level 3
        let width: i32 = 16;
    } // C. Exit... dump scope level 2
} // D. Exit... dump scope level 1
// E. Exit... dump scope level 0
```
* Ouput  
```
> Create symbol table (scope level 0)
func: main
> Insert `main` (addr: -1) to scope level 0
> Create symbol table (scope level 1)
INT_LIT 99
> Insert `height` (addr: 0) to scope level 1
> Create symbol table (scope level 2)
FLOAT_LIT 3.140000
> Insert `width` (addr: 0) to scope level 2

> Dump symbol table (scope level: 2)
Index     Name      Mut       Type      Addr      Lineno    Func_sig  
0         width     0         f32       1         4         -         
FLOAT_LIT 0.000000
> Insert `length` (addr: 1) to scope level 1
> Create symbol table (scope level 2)
STRING_LIT "hello world"
> Insert `length` (addr: 0) to scope level 2
> Create symbol table (scope level 3)
bool TRUE
> Insert `length` (addr: 0) to scope level 3

> Dump symbol table (scope level: 3)
Index     Name      Mut       Type      Addr      Lineno    Func_sig  
0         length    0         bool      4         10        -         
INT_LIT 16
> Insert `width` (addr: 1) to scope level 2

> Dump symbol table (scope level: 2)
Index     Name      Mut       Type      Addr      Lineno    Func_sig  
0         length    0         str       3         8         -         
1         width     0         i32       5         12        -         

> Dump symbol table (scope level: 1)
Index     Name      Mut       Type      Addr      Lineno    Func_sig  
0         height    0         i32       0         2         -         
1         length    0         f32       2         6         -         

> Dump symbol table (scope level: 0)
Index     Name      Mut       Type      Addr      Lineno    Func_sig  
0         main      -1        func      -1        1         (V)V      
Total lines: 15
```
## Get Started
* Compile source code and execute with input file  
`$make clean && make  
$ ./myscanner < input/a01_arithmetic.rs >| tmp.out`  
* Compare with the ground truth   
`$diff -y tmp.out answer/a01_arithmetic.out`  
* Check the output file char-by-char  
`$od -c answer/a01_arithmetic.out`  
