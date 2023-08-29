#include "tablequeue.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>


SYMBOL *new_symbol(char *name, int index, int mut, char *type, int address, int lineno, char *func_sig, char *array_type)
{
    SYMBOL *symbol = malloc(sizeof(SYMBOL));
    symbol->index = index;
    strncpy(symbol->name, name, NAME_SIZE);
    symbol->mut = mut;
    strncpy(symbol->type, type, 10);
    symbol->address = address;
    symbol->lineno = lineno;
    strncpy(symbol->func_sig, func_sig, NAME_SIZE);
    strncpy(symbol->array_type, array_type, 10);
    return symbol;
}

size_t Qsize(const QUEUE *queue)
{
    return sizeof(queue)/sizeof(QUEUE);
}

void AddParameter(char *name, const QUEUE *queue, char *type_name){
    struct node *current = queue->head;
    while (current != NULL) {
        SYMBOL *symbol = current->data;
        if (strcmp(symbol->name, name) == 0) {

            char id[10]= "";
            char temp_sig[10] = "";
            if(detectsig == -1){
                strcpy(id,"");
                strncpy(temp_sig,symbol->func_sig,1);
                temp_sig[1] = '\0';
                strcat(temp_sig, id);
                strcpy(symbol->func_sig,temp_sig);
                return;
            }

            if(strcmp(type_name, "i32")== 0){
                strcpy(id,"I");
            }
            else if(strcmp(type_name, "f32")== 0){
                strcpy(id,"F");
            }
            else if(strcmp(type_name, "bool")== 0){
                strcpy(id,"B");
            }
            else if(strcmp(type_name, "array")== 0)
            {
                strcpy(id,"A");
            }
            else if(strcmp(type_name, "str")== 0){
                strcpy(id,"S");
            }


            strncpy(temp_sig,symbol->func_sig,detectsig);
            temp_sig[detectsig] = '\0';
            strcat(temp_sig, id);
            strcpy(symbol->func_sig,temp_sig);
            detectsig++;
            return;
        }
        current = current->next;
    }


}

void AddReturn(char *name, const QUEUE *queue, char *type_name){
    struct node *current = queue->head;
    while (current != NULL) {
        SYMBOL *symbol = current->data;
        if (strcmp(symbol->name, name) == 0) {
            if(strcmp(type_name,"")==0){
                strcat(symbol->func_sig,")V");
            }
            else{

                if(strcmp(type_name, "i32")== 0){
                    strcat(symbol->func_sig,")I");
                }
                else if(strcmp(type_name, "f32")== 0){
                    strcat(symbol->func_sig,")F");
                }
                else if(strcmp(type_name, "bool")== 0){
                    strcat(symbol->func_sig,")B");
                }
                else if(strcmp(type_name, "array")== 0)
                {
                    strcat(symbol->func_sig,")A");
                }
                else if(strcmp(type_name, "str")== 0){
                    strcat(symbol->func_sig,")S");
                }
            }
            return;
        }
        current = current->next;
    }
    
}