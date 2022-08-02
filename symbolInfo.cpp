#include "SymbolInfo.h"

// constructor
SymbolInfo::SymbolInfo(string n, string t)
{
    name = n;
    type = t;
    next = NULL;
}
SymbolInfo::SymbolInfo(char *n, char *t)
{
    name = string(n);
    type = string(t);
    next = NULL;
}

string SymbolInfo::getName()
{
    return name;
}

void SymbolInfo::setName(string n)
{
    name = n;
}

string SymbolInfo::getType()
{
    return type;
}

void SymbolInfo::setType(string t)
{
    type = t;
}

void SymbolInfo::setReturnType(string type)
{
    return_type = type;
    return;
}

string SymbolInfo::getReturnType()
{
    return return_type;
}

void SymbolInfo::setArraySize(int sz)
{
    array_size = sz;
    return;
}
int SymbolInfo::getArraySize()
{
    return array_size;
}
int SymbolInfo::getParameterSize()
{
    return parameter_list.size();
}

void SymbolInfo::addParameter(string type, string name)
{
    exm_parameter.parameter_type = type;
    exm_parameter.parameter_name = name;

    parameter_list.push_back(exm_parameter);
    return;
}
SymbolInfo::parameter SymbolInfo::getParameter(int index)
{
    return parameter_list[index];
}