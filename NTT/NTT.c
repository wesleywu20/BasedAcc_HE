#include "NTT.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <string.h>

static int numPrimeFactors;

/* determines whether input number is prime */
static bool is_prime(int number) {
    if (number == 0 | number == 1)
        return true;
    for (int i = 2; i <= number / 2; i++) {
        if (number % i == 0)
            return false;
    }
    return true;
}

/* generates dynamically allocated array of prime factors of input n */
static int * primeFactors(int n)
{
    // Print the number of 2s that divide n
    int * factors = NULL;
    numPrimeFactors = 0;
    while (n % 2 == 0)
    {
        factors = (int *) realloc(factors, (numPrimeFactors + 1));
        factors[numPrimeFactors] = 2;
        numPrimeFactors++;
        n /= 2;
    }
 
    // n must be odd at this point.  So we can skip
    // one element (Note i = i +2 )
    for (int i = 3; i <= sqrt(n); i += 2)
    {
        // While i divides n, print i and divide n
        while (n % i == 0)
        {
            factors = (int *) realloc(factors, (numPrimeFactors + 1));
            factors[numPrimeFactors] = i;
            numPrimeFactors++;
            n /= i;
        }
    }
    
    if (is_prime(n)) {
        factors = (int *) realloc(factors, (numPrimeFactors + 1));
        factors[numPrimeFactors] = n;
        numPrimeFactors++;
    }

    return factors;
}

/* Iterative Function to calculate (x^n)%p in
   O(logy) */
int power(int x, unsigned int y, int p)
{
    u_int64_t res = 1;     // Initialize result
 
    x = x % p; // Update x if it is more than or
    // equal to p
 
    while (y > 0)
    {
        // If y is odd, multiply x with result
        if (y & 1)
            res = (res*x) % p;
 
        // y must be even now
        y = y >> 1; // y = y/2
        x = (x*x) % p;
    }
    return res;
}

int primitive_root(int q) {
    int primitive_root = 0;
    int s = is_prime(q) ? q - 1 : q;
    int * prime_factors = primeFactors(s);
    for (int r = 2; r <= s; r++)
    {
        // Iterate through all prime factors of phi.
        // and check if we found a power with value 1
        bool flag = false;
        for (int i = 0; i < numPrimeFactors; i++)
        {
            // Check if r^((phi)/primefactors) mod n
            // is 1 or not
            if (power(r, s/prime_factors[i], q) == 1)
            {
                flag = true;
                break;
            }
         }
 
         // If there was no power with value 1.
         if (flag == false)
           return r;
    }
    return -1;
}

static int find_mod_inverse(int num, int mod) {
    for (int i = 0; i < mod; i++) {
        if ((i * num) % mod == 1)
            return i;
    }
    return -1;
}

/* 
Convert a polynomial to frequency domain using NTT

a - input polynomial
b - result array
n - input polynomial length
k - arbitrary integer
mod - mod base

NOTE: for k, choose a value s.t. q = n * k + 1 is prime
*/
void naive_ntt(int * a, int * b, int n, int k, int mod) {
    int q = n * k + 1;
    assert(is_prime(q) == 1);
    int x = primitive_root(q);
    int w = power(x, k, mod);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            b[i] += a[j] * power(w, i * j, mod);
        }
        b[i] %= mod;
    }
}

void naive_intt(int * a, int * b, int n, int k, int mod) {
    int q = n * k + 1;
    assert(is_prime(q) == 1);
    int x = primitive_root(q);
    int w = power(x, k, mod);
    int mod_inverse_w = find_mod_inverse(w, mod);
    int mod_inverse_n = find_mod_inverse(n, mod);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            b[i] += a[j] * power(mod_inverse_w, i * j, mod);
        }
        b[i] %= mod;
        b[i] *= mod_inverse_n;
        b[i] %= mod;
    }
}

void ntt_multiply(int * a, int * b, int * c, int n, int k, int mod) {
    for (int i = 0; i < n; i++) {
        c[i] = (a[i] * b[i]) % mod;
    }
}