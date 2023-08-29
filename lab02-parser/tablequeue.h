#ifndef TABLEQUEUE_H
#define TABLEQUEUE_H

#define NAME_SIZE 64
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

typedef struct
{
    int index;
    char name[NAME_SIZE];
    int mut;
    char type[10];
    int address;
    int lineno;
    char func_sig[NAME_SIZE];
    char array_type[10];
} SYMBOL;

struct node
{
    SYMBOL *data;
    struct node *next;
} NODE;

struct tableQueue
{
    struct node *head;
    size_t size;
};

SYMBOL *new_symbol(char *name, int index, int mut, char *type, int address, int lineno, char *func_sig, char *array_type);
typedef struct tableQueue QUEUE;    // 一個symbol table

size_t Qsize(const QUEUE *queue);
void AddParameter(char *name, const QUEUE *queue, char *type_name);
void AddReturn(char *name, const QUEUE *queue, char *type_name);

QUEUE *tables[100];     //所有symbol table
QUEUE *currentTable;      //目前symbol table
int scopeLevel;
int address;
int detectsig;
#endif