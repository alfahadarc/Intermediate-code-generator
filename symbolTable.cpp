#include "SymbolTable.h"
extern FILE *logout;
// extern FILE *tokenout;

SymbolTable::SymbolTable()
{
    current = NULL;
    counter = 0;
}

SymbolTable::SymbolTable(int n)
{
    current = NULL;
    counter = 0;
    buckets = n;
}
void SymbolTable::enterScope()
{
    ScopeTable *newScopeTable = new ScopeTable(buckets);

    if (current != NULL)
    { // more here

        newScopeTable->id = current->id + "." + to_string(current->children + 1);
        current->children = current->children + 1;

        newScopeTable->parentScope = current;
        current = newScopeTable;
    }
    else
    {
        counter++;
        current = newScopeTable;
        current->id = to_string(counter);
    }
}
void SymbolTable::exitScope()
{
    if (current != NULL)
    {
        string id = current->id;
        ScopeTable *temp = current->parentScope;
        delete current;
        current = temp;
    }
    else
    {
    }
}

bool SymbolTable::insertInTable(string key, string type)
{
    // null check
    if (current != NULL)
    {
        if (current->insert(key, type))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
        // create a current and add as current null
        ScopeTable *newScopeTable = new ScopeTable(buckets);
        counter++;
        current = newScopeTable;
        current->id = to_string(counter);

        // now insert
        if (current->insert(key, type))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
}

bool SymbolTable::insertInTable_Symbol(SymbolInfo *p)
{
    // null check
    if (current != NULL)
    {
        if (current->insertSymbol(p))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
        // create a current and add as current null
        ScopeTable *newScopeTable = new ScopeTable(buckets);
        counter++;
        current = newScopeTable;
        current->id = to_string(counter);

        // now insert
        if (current->insertSymbol(p))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
}

bool SymbolTable::removeFromTable(string key)
{
    // null check
    if (current != NULL)
    {
        if (current->deleteItem(key))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {

        return false;
    }
}
SymbolInfo *SymbolTable::lookUpCurrent(string name)
{
    if (current == NULL)
    {
        return NULL;
    }
    return current->lookUp(name);
}
SymbolInfo *SymbolTable::lookUpTable(string key)
{
    ScopeTable *search = current;
    SymbolInfo *symbol;

    while (search != NULL)
    {
        symbol = search->lookUp(key);
        if (symbol != NULL)
        {
            return symbol;
        }
        else
        {
            search = search->parentScope;
        }
    }

    return NULL;
}

void SymbolTable::printCurrentScopeTable()
{
    if (current != NULL)
    {
        cout << "ScopeTable # " << current->id << endl;
        current->print();
        cout << endl;
    }
    else
    {
    }
}

void SymbolTable::printAllScopeTable()
{
    if (current != NULL)
    {
        ScopeTable *search = current;
        while (search != NULL)
        {
            fprintf(logout, "ScopeTable # %s \n", search->id.c_str());
            // cout << "ScopeTable # " << search->id << endl;
            search->print();
            search = search->parentScope;
            // cout << endl;
        }
    }
    else
    {
    }
}

SymbolTable::~SymbolTable()
{
    ScopeTable *search = current;
    ScopeTable *p;
    while (search != NULL)
    {
        p = search;
        search = search->parentScope;
        delete p;
    }
}