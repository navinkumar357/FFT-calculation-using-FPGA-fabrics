
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <complex.h>


#undef I
#define j _Complex_I

#define N 8

double complex arr[N];

void populate(){

    srand(N);
    for (int i = 0; i < N; i++) {
        arr[i] = rand();
        printf(" %lf + %lfi", creal(arr[i]), cimag(arr[i]));
    }
    printf("\n");
    printf("Initialized Array\n");
}

int oddoreven(int n)
{
    return n%2==0;
}

void cooley_tukey(double complex *arr, int len)
{
    int odd = 0, even = 0, n[len], half, factor;
    double complex oddarr[len/2], evenarr[len/2];

    if(len>2)
    {

        for(int i=0; i<len; i++)
        {
            if(!oddoreven(i)){
                oddarr[odd++] = arr[i];
            }
            else{
                evenarr[even++] = arr[i];
            }
        }
        cooley_tukey(oddarr,len/2);
        cooley_tukey(evenarr,len/2);

    }
    else
    {
        oddarr[0]=arr[1];
        evenarr[0]=arr[0];
    }


    half = len/2;

    double complex t;
    for (int k = 0; k < len/2; k++) {
		t = (cexp(-2 * j * M_PI * k / len)) * oddarr[k];
		arr[k] = evenarr[k] + t;
		arr[len/2 + k] = evenarr[k] - t;
    }
}

void main(){
    populate();
    cooley_tukey(arr,N);

    for (int i = 0; i < N; i++) {
        printf(" %lf + %lfi \n", creal(arr[i]), cimag(arr[i]));
    }
    printf("\n");
    printf("\n");
    printf("FFT result \n");

}
