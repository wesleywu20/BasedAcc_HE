#define POLYNOMIAL_SIZE 4096

// #define _GNU_SOURCE
#include <asm/unistd.h>
#include <linux/perf_event.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <inttypes.h>
#include <sys/types.h>

// based on
// https://stackoverflow.com/questions/13313510/quick-way-to-count-number-of-instructions-executed-in-a-c-program

// can compile with "gcc -ggdb3 -O0 -std=c++11 -Wall -Wextra -pedantic -o poly poly.c" -> works without flags
// sudo ./poly

typedef uint32_t coeff_prec;
// typedef uint64_t coeff_prec;
// typedef unsigned __int128 coeff_prec;

long perf_event_open(struct perf_event_attr *hw_event, pid_t pid, int cpu, int group_fd, unsigned long flags) {
    int ret;

    ret = syscall(__NR_perf_event_open, hw_event, pid, cpu, group_fd, flags);
    return ret;
}

void multiply(coeff_prec A[], coeff_prec B[], coeff_prec C[]) {
    for (int i = 0; i < POLYNOMIAL_SIZE; i++)
        for (int j = 0; j < POLYNOMIAL_SIZE; j++)
            C[i + j] += A[i] * B[j];
}

int main() {
    int fd;
    long long count;
    struct perf_event_attr pe;

    memset(&pe, 0, sizeof(struct perf_event_attr));
    pe.type = PERF_TYPE_HARDWARE;
    pe.size = sizeof(struct perf_event_attr);
    pe.config = PERF_COUNT_HW_INSTRUCTIONS;
    pe.disabled = 1;
    pe.exclude_kernel = 1;
    pe.exclude_hv = 1;

    fd = perf_event_open(&pe, 0, -1, -1, 0);
    if (fd == -1) {
        fprintf(stderr, "Error opening leader %llx\n", pe.config);
        exit(EXIT_FAILURE);
    }

    // setup polynomial
    int i;
    coeff_prec *A = (coeff_prec *)malloc((POLYNOMIAL_SIZE) * sizeof(coeff_prec));
    coeff_prec *B = (coeff_prec *)malloc((POLYNOMIAL_SIZE) * sizeof(coeff_prec));
    coeff_prec *C = (coeff_prec *)malloc((POLYNOMIAL_SIZE * 2 - 1) * sizeof(coeff_prec));
    memset(C, 0, (POLYNOMIAL_SIZE * 2 - 1) * sizeof(coeff_prec));
    for (i = 0; i < POLYNOMIAL_SIZE; i++) {
        A[i] = i;
        B[i] = i;
    }

    ioctl(fd, PERF_EVENT_IOC_RESET, 0);
    ioctl(fd, PERF_EVENT_IOC_ENABLE, 0);

    // Code to be measured
    multiply(A, B, C);
    // Code to be measured

    ioctl(fd, PERF_EVENT_IOC_DISABLE, 0);
    read(fd, &count, sizeof(long long));

    printf("Using C %ld\n", (long int)C[0]);

    printf("Instructions executed: %lld\n", count);

    close(fd);
    return 0;
}