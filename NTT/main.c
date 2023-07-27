#include "NTT.h"
#include <stdio.h>
#include <stdlib.h>

int main() {
    int mod = 649;
    int k = 84;
    int n = 8;

    printf("perform NTT on x\n");
    int x[8] = {4, 1, 4, 2, 1, 3, 5, 6};
    int * x_ntt = (int *)malloc(n * sizeof(int));
    naive_ntt(x, x_ntt, n, k, mod);

    printf("perform NTT on y\n");
    int y[8] = {6, 1, 8, 0, 3, 3, 9, 8};
    int * y_ntt = (int *)malloc(n * sizeof(int));
    printf("alloced y\n");
    naive_ntt(y, y_ntt, n, k, mod);

    // int ntt_prod[8];
    // ntt_multiply(x_ntt, y_ntt, ntt_prod, n, k, mod);
    // int prod_inv[8];
    // naive_intt(ntt_prod, prod_inv, n, k, mod);
    // for (int i = 0; i < n; i++) {
    //     printf("prod_inv[%d]: %d\n", i, prod_inv[i]);
    // }

    printf("free x\n");
    free(x_ntt);
    printf("free y\n");
    free(y_ntt);
    return 0;
}