
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <complex.h>
#include "inReal.h"

#define len 16

typedef struct cn
{
    float real;
    float imag;
} cmplx;

//Complex Multiplication

cmplx cadd(cmplx a , cmplx b){
    cmplx c;
    c.real = a.real + b.real;
    c.imag = a.imag + b.imag;

    return c;
}

cmplx csub(cmplx a , cmplx b){
    cmplx c;
    c.real = a.real - b.real;
    c.imag = a.imag - b.imag;

    return c;
}

cmplx cmul(cmplx a , cmplx b){
    cmplx c;

    c.real = a.real * b.real - a.imag * b.imag;
    c.imag = a.real * b.imag + b.real * a.imag;

    return c;
}

void populate(cmplx *arr){
    for(int i=0; i < len; i++){
        arr[i].real = inReal[i];
        arr[i].imag = 0;
    }
}

void cooley_tukey(cmplx *arr, cmplx *oparr)
{
    cmplx tmparr[len];
    int n=log2(len), bin[n], storarr[n], nos[n];
    int half = len/2;
    cmplx wm;

    for (int i = 0; i < len; i++){

        int a = i, val = 0, base = 1;

        for(int j = 0; j < n; j++){
            bin[j] = a & 0x01 ? 1 : 0;
            //printf("%d ", bin[j]);
            a>>=1;
        }

        printf("\n");

       for (int k = n-1; k > -1; k--){
            val = val + bin[k] * base;
            base = base * 2;
        }
        printf("New Address Order: ");
        printf("%d ", val);

        tmparr[val].real = arr[i].real;
        tmparr[val].imag = arr[i].imag;
    }

    printf("\n \n");

    for (int i = 0; i < len; i++){
        oparr[i].real = tmparr[i].real;
        oparr[i].imag = tmparr[i].imag;
    }

    //Finished Bit reversal.

    printf("Reordered Array vs Original Array:\n");
    for(int y=0; y<len; y++)
    {
        printf("%f + %fi || %f + %fi\n", oparr[y].real, oparr[y].imag, arr[y].real, arr[y].imag);
    }
    printf("\n\n");



    cmplx t, J, w, u;

    //const complex<double> J(0, 1);
    J.real = 0;
    J.imag = 1;

    t.real = 0;
    t.imag = 0;

    wm.real = 0;
    wm.imag = 0;

    for (int s = 1; s <= log2(len) ; ++s)
    {
        int m = 1 << s; // 2 power s
        int m2 = m>>1; // m2 = m/2 -1

        //cd w(1, 0);

        w.real = 1;
        w.imag = 0;
        //cd wm = exp(J * (PI / m2));
        //wm = cexpf(mul.imag);

        wm.real =  cos((J.real) * 2*(M_PI / m));
        wm.imag =  -sin((J.imag) * 2*(M_PI / m));

        for (int j = 0; j < m2; ++j)
        {
            for (int k = j; k < len; k += m)
            {

                // t = twiddle factor
                //cd t = w * A[k + m2];
                //cd u = A[k];
                t = cmul(w, oparr[k+m2]);
                u = oparr[k];

                // similar calculating y[k]
                //A[k] = u + t;
                oparr[k] = cadd(u,t);

                // similar calculating y[k+n/2]
                //A[k + m2] = u - t;
                oparr[k + m2] = csub(u,t);
            }
            //w *= wm;
            w = cmul(w,wm);
        }
    }

    printf("The result:");
    for (int j = 0; j < len; j++)
    {
        printf("%1.1f + %1.1fi, \n", oparr[j].real, oparr[j].imag);
        if(j==len-1)
            printf("\n \n");
    }
}

//do dft like in recursive by calculating dft of strides of two then four till len/2 to calculate DFT
void main()
{
    cmplx array[len], oparray[len];
    int stride, half = len/2;

    populate(array);

    printf("\n");
    printf("Initial Array \n");
    /*for (int j = 0; j < len; j++)
    {
        printf("%1.1f ", array[j].real);
        if(j==len-1)
            printf("\n \n");
    }*/


    cooley_tukey(array,oparray);


}
