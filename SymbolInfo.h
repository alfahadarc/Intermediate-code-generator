#ifndef SYMBOLINFO_H
#define SYMBOLINFO_H
#include <string>
#include <vector>
using namespace std;

class SymbolInfo
{
private:
    string name;
    string type;

    // new added
    string return_type;
    int array_size;

public:
    // function parameter and type
    struct parameter
    {
        string parameter_type;
        string parameter_name;
    } exm_parameter;

    // list of all parameter of a function
    vector<parameter> parameter_list;

    SymbolInfo *next;
    SymbolInfo(string n, string t);
    SymbolInfo(char *n, char *t);
    string getName();
    void setName(string n);
    string getType();
    void setType(string t);

    // new added

    // variable type and function ret type check
    void setReturnType(string type);
    string getReturnType();

    void setArraySize(int sz);
    int getArraySize(); //-1 var, -2 function decl, -3 defination
    int getParameterSize();

    void addParameter(string type, string name);

    parameter getParameter(int index);
};

#endif
