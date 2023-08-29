# Java Assembly Code Generator
*Compiler 2023 Programming Assignment III
Compiler for Java Assembly Code Generation*  
  
**a code generator for generating Java assembly code (for Java Virtual Machines) of the given μRust program**  


## Environment
For Linux  
>Ubuntu 20.04 LTS

Install Dependencies
>`$ sudo apt install flex bison`  
>Java Virtual Machine (JVM): `$ sudo apt install default-jre`

local judge:
`pip3 install local-judge`


## Get Started
* Compile source code and execute with input file
```
make clean && make
./mycompiler < input.rs java -jar jasmin.jar hw3.j java Main
```

