
#include <fstream>
#include <iostream>

int a[10],book[10],n;

void dfs(int step){
    int i;
    if (step == n ) {
        for (i=1; i<=n - 1; i++) {
            printf(" %d",a[i]);
        }
        printf("\n");
    }
    
    for (i=1; i<=n; i++) {
        if (book[i]==0 ) {
            a[step]=i;
            book[i]=1;
            
            dfs(step + 1);
            
            book[i]=0;
        }
    }
    return;
}

int main(int argc, const char * argv[]) {
printf("asdf");
    std::ifstream infile("thefile.txt");
    
    int a, b;
    while (infile >> a >> b)
    {
        printf("%d %d", a, b);
    }
    getchar();
    return 0;
}
