#define POLY 1
// typedef unsigned __int128 coeff_prec;

long long A[POLY];
long long B[POLY];
long C[2*POLY-1];

int main(void){


	for(int i=0;i<POLY;i++){
		for(int j=0;j<POLY;j++){
			C[i+j] += A[i]*B[j];
		}
	}

	return 51;
}
