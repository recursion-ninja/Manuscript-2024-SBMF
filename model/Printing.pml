#ifndef IMPORT_SPEC_PRINTING
#define IMPORT_SPEC_PRINTING

#include "Bit-Array.pml"
#include "Parameterized-Constants.pml"
#include "Global-State.pml"
#include "TreeKEM-v1.pml"


/********
    *
    * Global state priniting utilities:
    *   - print_challenges
    *   - print_membership
    *   - print_user_hoarding
    *   - print_user_corrupted
    *
********/


inline print_challenges ( )
{
    d_step {
        if
        :: challenged -> printf ( "\n\tChallenged:\tTrue\n"  );
        :: else       -> printf ( "\n\tChallenged:\tFalse\n" );
        fi
    }
}


inline print_membership ( )
{
    d_step {
        printf ( "\n\tLargest ID:\t%d\n", widestID );
        
        printf ( "\n\tMembership (val): %d", membership );
        printf ( "\n\tMembership (arr):" );
        unsigned p : BITS_USERID;
        for ( p : FIRST_USERID .. FINAL_USERID )
        {
            if
            :: CheckBit( membership, p ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
            :: else                      -> printf ( "\n\t  %d [\tFalse\t]", p )
            fi
        };
        printf ( "\n" );
    }
}


inline print_user_hoarding ( )
{
    d_step {
        unsigned p : BITS_USERID;
        
        printf ( "\n\tHoarding Prior:" );
        for ( p : FIRST_USERID .. FINAL_USERID )
        {
            if
            :: CheckBit( hoardPrior, p ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
            :: else                      -> printf ( "\n\t  %d [\tFalse\t]", p )
            fi
        }
        printf ( "\n" );

        printf ( "\n\tHoarding Newly:" );
        for ( p : FIRST_USERID .. FINAL_USERID )
        {
            if
            :: CheckBit( hoardNovel, p ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
            :: else                      -> printf ( "\n\t  %d [\tFalse\t]", p )
            fi
        }
        printf ( "\n" );
    }
}


inline print_user_corrupted ( )
{
    d_step {
        printf ( "\n\tRequired healing:" );
        unsigned p : BITS_USERID;
        for ( p : FIRST_USERID .. FINAL_USERID )
        {
            if
            :: CheckBit( memberKeys, p ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
            :: else                      -> printf ( "\n\t  %d [\tFalse\t]", p )
            fi
        }
        printf ( "\n" );
    }
}


/********
    *
    * Entire state priniting utilities:
    *   - print_entire_state
    *
********/


inline print_entire_state ( )
{
    d_step
    {
        printf ( "\n-=-=-=-=-=-=-=-=-=-=-=-\n-=-  GLOBAL  STATE  -=-\n-=-=-=-=-=-=-=-=-=-=-=-\n" );
        print_challenges         ( );
        printf ( "\n\tNon-Commitment Options:\t[ %d, %d, %d ]\n", CheckBit (nonCommitmentOptions, 0), CheckBit (nonCommitmentOptions, 1), CheckBit (nonCommitmentOptions, 2) );
        printf ( "\n\tNon-Commitment Ability:\t%d\n", nonCommitmentOptions != 0 );
        print_membership         ( );
        print_user_hoarding      ( );
        print_user_corrupted     ( );
        print_attacker_knowledge ( );
    }
}


#endif /* IMPORT_SPEC_PRINTING */
