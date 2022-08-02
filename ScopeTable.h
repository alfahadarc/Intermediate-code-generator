#ifndef SCOPETABLE_H
#define SCOPETABLE_H
#include "SymbolInfo.h"
#include <string.h>
#include <iostream>
using namespace std;

class ScopeTable
{
private:
    int total_buckets;
    SymbolInfo **list;

public:
    // parent
    ScopeTable *parentScope;
    // id
    string id;
    // no of child
    int children;

    ScopeTable(int n);
    ~ScopeTable();
    uint32_t sdbmhash(string str);
    unsigned int hashFunction(string name);
    bool insert(string key, string value);
    SymbolInfo *lookUp(string symbol);
    SymbolInfo *serchForInsert(string symbol);
    bool deleteItem(string key);
    void print();
    // new additon
    bool insertSymbol(SymbolInfo *p);
};

#endif