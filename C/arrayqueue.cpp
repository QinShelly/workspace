#include <iostream>

int main(int argc, const char * argv[]) {

    int q[102] = {0,6,3,1,7,5,8,9,2,4}, head, tail;
    
    head = 1;
    tail = 10;
    
    while (head < tail) { //queue not empty
        printf("%d ", q[head]);
        head++; // shift
        
        q[tail] = q[head];
        tail++; //push
        
        head++; //shift
    }
    
    return 0;
}
