

#include <iostream>

int main(int argc, const char * argv[]) {
    char a[101];
    strcpy(a, "abcdcba");
    char s[101];
    int top;
    long i,len, mid , next;
    //&a = "abccba";
    len = strlen(a);
    mid = len/2 -1;
    top = 0;
    
    for (i=0; i<=mid; i++) {
        s[++top] = a[i];
        
    }
    
    if (len%2 == 0) {
        next = mid + 1;
    } else  {
        next = mid + 2;
    }
    
    for (i = next; i<=len - 1; i++) {
     
        if (a[i] != s[top]) {
            break;
        }
        top--;
    }
    if (top == 0) {
        printf("yes");
    } else{
        printf("no");
    }
    
    return 0;
}
