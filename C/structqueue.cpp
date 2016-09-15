
#include <iostream>

struct queue {
    int data[100];
    int head;
    int tail;
};

int main(int argc, const char * argv[]) {
   
    struct queue q;

    q.head = 1;
    q.tail = 1;
    
    for (int i=1; i<=9; i++) {
        q.data[q.tail] = i;
        q.tail++;
    }
    
    while(q.head<q.tail){
        printf("%d ",q.data[q.head]);
        q.head++;
        q.data[q.tail] = q.data[q.head];
        q.tail++;
        q.head++;
    }
    
    return 0;
}
