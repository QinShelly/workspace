#include <iostream>

int a[10],book[10],n;

void dfs(int step){
    int i;
    if (step == n + 1) {
        for (i=1; i<=n; i++) {
            printf(" %d",a[i]);
        }
        printf("\n");
    }
    
    for (i = 1; i <= n; i++) {
        if (book[i] == 0 ) {
            a[step] = i;
            book[i] = 1;
            
            dfs(step + 1);
            
            book[i] = 0;
        }
    }
    return;
}

int main(int argc, const char * argv[]) {
    scanf("%d",&n);
    dfs(1);
    getchar();
    return 0;
}
