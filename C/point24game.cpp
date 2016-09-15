#include <iostream>
#include <stdlib.h>
#include <string>

double number[4];
std::string result[4];

bool PointGame(int n){
    if (n == 1) {
        if (number[0]  == 24){
            return true;
        }
        else {
            return false;
        }
    }
    
    for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++){
            double a, b;
            std::string expa;
            std::string expb;
            
            a = number[i];
            b = number[j];
            number[j] = number[n - 1];
            
            expa = result[i];
            expb = result[j];
            result[j] = result[n - 1];
            
            result[i] = '(' + expa + '+' + expb + ')'  ;
            number[i] = a + b;
            if (PointGame(n - 1))
                return true;
            
            result[i] = '(' + expa + '-' + expb + ')'  ;
            number[i] = a - b;
            if (PointGame(n - 1))
                return true;
            
            result[i] = '(' + expb + '-' + expa + ')'  ;
            number[i] = b - a;
            if (PointGame(n - 1))
                return true;
            
            number[i] = a;
            number[j] = b;
            result[i] = expa;
            result[j] = expb;
        }
    }
    
    return false;
}

int main(int argc, const char * argv[])
{
    int x;
    char buffer[20];
    for (int i = 0; i < 4; i++) {
        std::cout << "the " << i << "number:";
        std::cin >> x;

        number[i] = x;
        sprintf(buffer,"%d",x);
        result[i] = buffer; 
    }
       
    if (PointGame(4)){
        std::cout << "success" << std::endl;
    }
    else{
        std::cout << "failed" << std::endl;
    }
    
    std::cout << result[0];
    
    return 0;
}

