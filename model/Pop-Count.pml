#ifndef IMPORT_SPEC_POPCOUNT
#define IMPORT_SPEC_POPCOUNT

#include "Parameterized-Constants.pml"

#if N <= 8
/*
    IMPORTANT NOTE:
        Equivalent for all:
            - ( unsigned pop_in  : b )
            - ( unsigned pop_out : b )
        where:
            - ( b ) in [1, 8]
            - ( pop_in ) and ( pop_out ) are the same dimension ( b ).

    Three assignments for N <= 8 ...

    mask-1 = 55_{16} =  85_{10} = 01010101_{2}
    mask-2 = 33_{16} =  51_{10} = 00110011_{2}
    mask-3 = 07_{16} =   7_{10} = 00000111_{2}

    out = (in        ) - ((in  >> 1) & 0x55);
    out = (out & 0x33) + ((out >> 2) & 0x33);
    out = (out & 0x07) + ((out >> 4) & 0x07);
*/
#define PopCount( pop_in, pop_out ) \
atomic { \
    pop_out = (pop_in      ) - ((pop_in  >> 1) & 85); \
    pop_out = (pop_out & 51) + ((pop_out >> 2) & 51); \
    pop_out = (pop_out &  7) + ( pop_out >> 4      ); \
}
#else
/*
    IMPORTANT NOTE:
        Equivalent for all:
            - ( unsigned pop_in  : b )
            - ( unsigned pop_out : b )
        where:
            - ( b ) in [1, 16]
            - ( pop_in ) and ( pop_out ) are the same dimension ( b ).

    Four assignments for 9 <= N ...

    mask-1 = 5555_{16} = 21845_{10} = 0101010101010101_{2}
    mask-2 = 3333_{16} = 13107_{10} = 0011001100110011_{2}
    mask-3 = 0F0F_{16} =  3855_{10} = 0000111100001111_{2}
    mask-4 = 000F_{16} =    15_{10} = 0000000000001111_{2}

    out = (in          ) - ((in  >> 1) & 0x5555);
    out = (out & 0x3333) + ((out >> 2) & 0x3333);
    out = (out & 0x0F0F) + ((out >> 4) & 0x0F0F);
    out = (out & 0x0707) + ((out >> 8) & 0x0707);
*/
#define PopCount( pop_in, pop_out ) \
atomic { \
    pop_out = ( pop_in          ) - ( ( (pop_in) >> 1 ) & 21845 ); \
    pop_out = ( pop_out & 13107 ) + ( (  pop_out >> 2 ) & 13107 ); \
    pop_out = ( pop_out &  3855 ) + ( (  pop_out >> 4 ) &  3855 ); \
    pop_out = ( pop_out &    15 ) + ( (  pop_out >> 8 )         ); \
}
#endif


#endif /* IMPORT_SPEC_POPCOUNT */
