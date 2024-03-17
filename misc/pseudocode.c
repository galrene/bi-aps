#include <stdio.h>
#include <math.h>

int isPrime ( int num ) {
    for ( int i = 2; i < num; i++ )
        if ( num % i == 0 && i != num  )
            return 0;
    return 1;
}


void arePrimes ( int arr [], int size ) {
    for ( int i = 0; i < size; i++ ) {
        if ( isPrime ( arr[i] ) )
            arr[i] = 1;
        else
            arr[i] = 0;
        printf ( "%d ", arr[i] );
    }
}

int main ( void ) {
    int arr [] = { -5, 1, 0, 7, 14, 573489 };
    int arrSize = 6;
    int x = 1;
    int y = 1;
    if ( x )
        if ( y )
            puts("works");

    // arePrimes ( arr, arrSize );
    return 0;
}



