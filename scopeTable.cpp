#include "ScopeTable.h"
extern FILE *logout;
// extern FILE *tokenout;

// hash function
uint32_t ScopeTable::sdbmhash(string str)
{
    uint32_t hash = 0;
    unsigned int i = 0;
    unsigned int len = str.length();

    for (i = 0; i < len; i++)
    {
        hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
    }

    return hash;
}
unsigned int ScopeTable::hashFunction(string name)
{
    return sdbmhash(name) % total_buckets;
}

ScopeTable::ScopeTable(int n)
{
    total_buckets = n;
    list = new SymbolInfo *[total_buckets];

    // testing error
    for (int i = 0; i < total_buckets; i++)
    {
        list[i] = NULL;
    }

    parentScope = NULL;
    children = 0;
}

SymbolInfo *ScopeTable::lookUp(string key)
{
    SymbolInfo *p;
    int n = 0;

    for (p = list[hashFunction(key)]; p != NULL; p = p->next)
    {
        if (key.compare(p->getName()) == 0)
        {

            return p;
        }
        n++;
    }
    return NULL;
}

SymbolInfo *ScopeTable::serchForInsert(string key)
{
    SymbolInfo *p;
    for (p = list[hashFunction(key)]; p != NULL; p = p->next)
    {
        if (key.compare(p->getName()) == 0)
        {
            return p;
        }
    }
    return NULL;
}

bool ScopeTable::insert(string key, string value)
{

    SymbolInfo *p;

    if ((p = serchForInsert(key)) == NULL) // not found
    {

        SymbolInfo *newSymbol = new SymbolInfo(key, value);
        unsigned int hashval = hashFunction(key);

        SymbolInfo *head = list[hashval];
        if (head == NULL)
        {
            // empty list
            list[hashval] = newSymbol;

            return true;
        }
        else
        {
            // add to front linked list
            newSymbol->next = list[hashval];
            list[hashval] = newSymbol;

            return true;
        }
    }
    else
    {
        // already exists

        return false;
    }
}
// new addition to insert
bool ScopeTable::insertSymbol(SymbolInfo *p)
{
    if ((serchForInsert(p->getName())) == NULL) // not found
    {
        unsigned int hashval = hashFunction(p->getName());

        SymbolInfo *head = list[hashval];
        if (head == NULL)
        {
            // empty list
            list[hashval] = p;

            return true;
        }
        else
        {
            // add to front linked list
            p->next = list[hashval];
            list[hashval] = p;

            return true;
        }
    }
    else
    {
        // already exists

        return false;
    }
}

bool ScopeTable::deleteItem(string key)
{
    SymbolInfo *p;
    if ((p = lookUp(key)) == NULL)
    {
        // no entry

        return false;
    }
    else
    {
        SymbolInfo *previous, *current;
        unsigned int hashval = hashFunction(key);
        previous = current = list[hashval];
        int n = 0;

        while (current != NULL)
        {
            if (current == p)
            {
                if (current == list[hashval]) // head corner case
                {
                    list[hashval] = current->next;
                    delete current;

                    return true;
                }
                else
                {
                    previous->next = current->next;
                    // delete
                    delete current;

                    return true;
                }
            }
            else
            {
                current = current->next;
                previous = current;
                n++;
            }
        }
        return false;
    }
}

void ScopeTable::print()
{
    for (int i = 0; i < total_buckets; i++)
    {
        SymbolInfo *current = list[i];

        if (current != NULL)
        {
            fprintf(logout, "list: %d -> ", i);
            // cout << "list: " << i << " ";
            while (current != NULL)
            {
                fprintf(logout, "<%s:%s>", current->getName().c_str(), current->getType().c_str());
                // cout << "<" << current->getName() << " : " << current->getType() << ">";
                current = current->next;
            }
            fprintf(logout, "\n");
        }
    }
}

ScopeTable::~ScopeTable()
{
    for (int i = 0; i < total_buckets; i++)
    {
        SymbolInfo *current = list[i];
        SymbolInfo *n;
        while (current != NULL)
        {
            n = current->next;
            delete current;
            current = n;
        }
    }

    delete[] list;
}