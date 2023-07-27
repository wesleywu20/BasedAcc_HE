#include <gmp.h>
#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// #define DEBUG
#define OUTPUT

#define CONCAT(a, b) a b

#define __TARGET "bins_demo"
#define __N 64
#define __t 64
#define __Q 4294966657

#define __T 16
#define __L 7 // int(math.floor(math.log(self.q,self.T)))
#define __B 4 // int(math.floor(math.log(16,2)))

typedef int64_t precisionSigned;

void printPoly(precisionSigned *var, int count) {
    for (int i = 0; i < count; i++) {
        if (i % 3 == 0) {
            printf("\n");
        }
        printf("%ld ", var[i]);
    }
    printf("\n");
}

precisionSigned *readFile(char file[], int count) {
    precisionSigned *fileBuffer = malloc(count * sizeof(precisionSigned *));

    // reading from file
    FILE *file_pointer;
    file_pointer = fopen(file, "r");
    if (file_pointer == NULL) {
        printf("Error opening the file\n");
        exit(0);
    }
    int ret = fread(fileBuffer, sizeof(precisionSigned), count, file_pointer);
    if (ret != count) {
        printf("Error reading file\n");
        exit(0);
    }
    fclose(file_pointer);

    return fileBuffer;
}

void varFree(precisionSigned **var, int count) {
    for (int i = 0; i < count; i++) {
        free(var[i]);
    }
}

// this is emulating the python version of modulus.
// in verilog % can be insted of this function
void realMod(precisionSigned *var, precisionSigned modVal) {
    if (*var < 0) {
        while (*var < 0) {
            *var += modVal;
        }
    } else {
        *var %= modVal;
    }
}

// todo: update with a more optimized version
void gmt_HE_mul(const precisionSigned *poly1, const precisionSigned *poly2, precisionSigned *result) {

    // init gmp variables
    mpz_t *buffer = malloc(2 * __N * sizeof(mpz_t));
    for (int i = 0; i < 2 * __N; i++) {
        mpz_init(buffer[i]);
    }

    mpz_t *smallBuffer = malloc(3 * sizeof(mpz_t));
    for (int i = 0; i < 3; i++) {
        mpz_init(smallBuffer[i]);
    }

    mpz_t he_t;
    mpz_init(he_t);
    mpz_set_ui(he_t, __t);

    mpz_t he_q;
    mpz_init(he_q);
    mpz_set_ui(he_q, __Q);

#define REDUCED 1

    mpz_t he_qP;
    mpz_init(he_qP);
    mpz_set_ui(he_qP, __Q / (REDUCED * REDUCED));

    // poly multiplication using gmp library
    // cannot overflow as we are dividing by q
    for (int i = 0; i < __N; i++) {
        for (int j = 0; j < __N; j++) {
            mpz_set_si(smallBuffer[1], poly1[i] / REDUCED);
            mpz_set_si(smallBuffer[2], poly2[j] / REDUCED);
            mpz_mul(smallBuffer[0], smallBuffer[1], smallBuffer[2]);
            mpz_add(buffer[i + j], buffer[i + j], smallBuffer[0]);
        }
    }

    // gmp poly modulus
    for (int i = 0; i < __N; i++) {
        mpz_sub(buffer[i], buffer[i], buffer[i + __N]);
    }

    // gmp t div q % q -> cast to precisionSigned
    for (int i = 0; i < __N; i++) {
        mpz_fdiv_q(buffer[i], buffer[i], he_qP);
        mpz_mul(buffer[i], buffer[i], he_t);
        mpz_mod(buffer[i], buffer[i], he_q);

        // casting to precisionSigned
        result[i] = mpz_get_si(buffer[i]);
    }

    // Free the allocated memory for buffer and smallBuffer arrays
    for (int i = 0; i < 2 * __N; i++) {
        mpz_clear(buffer[i]);
    }
    free(buffer);

    for (int i = 0; i < 3; i++) {
        mpz_clear(smallBuffer[i]);
    }
    free(smallBuffer);

    mpz_clear(he_t);
    mpz_clear(he_q);
}

void baseTDecomp(precisionSigned *cypherText, precisionSigned *decomposedCyperText) {
    printf("Base T Decomposition (l, T) : (%d, %d)\n", __L, __T);
    for (int i = 0; i < __L + 1; i++) {
        for (int j = 0; j < __N; j++) {
            // Optimized version using binary operations when T == 16 -> can be implemented in HDL using slicing
            decomposedCyperText[i * __N + j] = (cypherText[j] >> (i * __B)) & 0xF;

            // how it should be done -> HDL
            // decomposedCyperText[i * __N + j] = (precisionSigned)((double)cypherText[j] / pow(__T, i)) % __T;

            // simplified version python version
            // precisionSigned qt = (precisionSigned)((double)cypherText[j] / __T); // rounding using casting
            // precisionSigned rt = cypherText[j] - qt * __T;
            // cypherText[j] = qt;
            // decomposedCyperText[i * __N + j] = rt;

        }
    }
}

#define REDUCE_RL 1
void polyMul_polyMod(const precisionSigned *poly1, const precisionSigned *poly2, precisionSigned *result) {
    precisionSigned *buffer = malloc((2 * __N) * sizeof(precisionSigned));
    memset(buffer, 0, (2 * __N) * sizeof(precisionSigned));

    // poly multiplication
    for (int i = 0; i < __N; i++) {
        for (int j = 0; j < __N; j++) {
            // overflow can happen as we are modding next
            buffer[i + j] = buffer[i + j] + ((poly1[i] / REDUCE_RL) * (poly2[j] / REDUCE_RL));
        }
    }

    // poly modulus
    for (int i = 0; i < __N; i++) {

        result[i] = buffer[i] - buffer[i + __N];

        // this is emulating the python version of modulus.
        realMod(&result[i], __Q / (REDUCE_RL * REDUCE_RL));
    }

    free(buffer);
}

void relinKeyReconstruction(precisionSigned *poly1, precisionSigned *poly2, precisionSigned *result) {
    precisionSigned *buffer = malloc(__N * sizeof(precisionSigned));

    polyMul_polyMod(poly1, poly2, buffer);

    for (int i = 0; i < __N; i++) {
        result[i] += buffer[i];

        // this is emulating the python version of modulus.
        realMod(&result[i], __Q);
    }

    free(buffer);
}

int main(int argc, char **argv) {

    // load contents to memory
    precisionSigned *ct_fresh[4];
    ct_fresh[0] = readFile(CONCAT(__TARGET, "/ct10_fresh.bin"), __N);
    ct_fresh[1] = readFile(CONCAT(__TARGET, "/ct11_fresh.bin"), __N);
    ct_fresh[2] = readFile(CONCAT(__TARGET, "/ct20_fresh.bin"), __N);
    ct_fresh[3] = readFile(CONCAT(__TARGET, "/ct21_fresh.bin"), __N);

    precisionSigned *relinKey;
    relinKey = readFile(CONCAT(__TARGET, "/relinKey.bin"), (__L + 1) * 2 * __N);

#ifdef DEBUG
    // verify contents
    printf("\n\nFresh Inputs\n");
    printPoly(ct_fresh[0], __N);
    printPoly(ct_fresh[1], __N);
    printPoly(ct_fresh[2], __N);
    printPoly(ct_fresh[3], __N);

    printf("\n\nRelin Key\n");
    printPoly(relinKey, (__L + 1) * 2 * __N);
#endif
    // HE multiplication
    printf("HE Multiplication\n");

    precisionSigned *r0 = malloc(__N * sizeof(precisionSigned));
    precisionSigned *r1 = malloc(__N * sizeof(precisionSigned));
    precisionSigned *r2 = malloc(__N * sizeof(precisionSigned));
    precisionSigned *r3 = malloc(__N * sizeof(precisionSigned));

    gmt_HE_mul(ct_fresh[0], ct_fresh[2], r0);
    gmt_HE_mul(ct_fresh[0], ct_fresh[3], r1);
    gmt_HE_mul(ct_fresh[1], ct_fresh[2], r2);
    gmt_HE_mul(ct_fresh[1], ct_fresh[3], r3);

    // adding (r1 + r2) % Q
    for (int i = 0; i < __N; i++) {
        r1[i] = r1[i] + r2[i];
        realMod(&r1[i], __Q);
    }

    // HE relinearization
    precisionSigned *ct2i = malloc((__L + 1) * __N * sizeof(precisionSigned));
    // baseTDecomp(ct_afterMul[2], ct2i);
    baseTDecomp(r3, ct2i);

    // relinerization
    printf("Relinearization\n");
    precisionSigned *result = malloc(__N * sizeof(precisionSigned));
    memset(result, 0, __N * sizeof(precisionSigned));
    for (int i = 0; i < __L + 1; i++) {
        relinKeyReconstruction(&ct2i[__N * i], &relinKey[i * (2 * __N) + 0 * __N], r0);
        relinKeyReconstruction(&ct2i[__N * i], &relinKey[i * (2 * __N) + 1 * __N], r1);
    }

#ifdef OUTPUT
    FILE *file;
    file = fopen("ctR0.bin", "wb");
    if (file == NULL) {
        perror("Error opening file");
        return 1;
    }
    fwrite(r0, sizeof(precisionSigned), __N, file);
    fclose(file);

    file = fopen("ctR1.bin", "wb");
    if (file == NULL) {
        perror("Error opening file");
        return 1;
    }
    fwrite(r1, sizeof(precisionSigned), __N, file);
    fclose(file);
#endif

    // free heap
    printf("freeing memory\n");
    varFree(ct_fresh, 4);
    free(relinKey);

    free(r0);
    free(r1);
    free(r2);
    free(r3);

    free(result);

    printf("Done\n");
    return 0;
}
