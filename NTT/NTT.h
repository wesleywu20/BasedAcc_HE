#include <stdio.h>
#include <stdbool.h>

int primitive_root(int q);
int * generate_twiddle_factors(int n, int q);
int reverse_bits(int number, int bit_length);
void naive_ntt(int * a, int * b, int n, int k, int mod);
void naive_intt(int * a, int * b, int n, int k, int mod);
void ntt_multiply(int * a, int * b, int * c, int n, int k, int mod);