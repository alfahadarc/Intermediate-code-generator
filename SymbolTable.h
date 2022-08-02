#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H
#include "ScopeTable.h"

class SymbolTable
{
private:
    /* data */
public:
    int buckets;
    int counter;
    ScopeTable *current;
    SymbolTable();
    SymbolTable(int n);
    ~SymbolTable();
    void enterScope();
    void exitScope();
    bool insertInTable(string name, string type);
    bool removeFromTable(string name);
    SymbolInfo *lookUpTable(string name);
    SymbolInfo *lookUpCurrent(string name);
    void printCurrentScopeTable();
    void printAllScopeTable();
    // new
    bool insertInTable_Symbol(SymbolInfo *p);
};

#endif