#include "Parameterized-Constants.pml"
#include "Bit-Array.pml"
#include "Pop-Count.pml"
#include "Selection.pml"
#include "Oracles.pml"
#include "Printing.pml"
#include "Global-State.pml"


//  #define SELECT_VIA_LOOP



         



         




         




         




         




         




         




         




         











         




























         




     

// 'Bit-Arrays' variables
local BITARRAY ( hoardPrior ); // Group membership of current epoch
local BITARRAY ( memberKeys ); // Members whose keys are known (corrupted), require an update/removal
local BITARRAY ( membership ); // Group membership of current epoch

// Scalar variables
local unsigned originID : 5; // ID of the  member
local unsigned targetID : 5; // ID of the effected member
local unsigned widestID : 4;      // The maximum ID during any past/present epoch.

// Knowledge flags
local bool learnedActiveKey; // Attacker learned the group's shared secret key during the key's epoch?
local bool learnedLegacyKey; // Attacker learned the group's shared secret key after  the key's epoch?









     



     



     






     
int attackerKnowledge;



     


inline attacker_initialize ( )
{
    d_step
    {
        attackerKnowledge = 0;
        learnedActiveKey  = false;
    }
}


inline attacker_learn_leaf ( memberID )
{
    // Attacker learns the node information
//    StampBit ( attackerKnowledge, 15 + memberID );
//    attacker_spine_from ( memberID );

    d_step
    {
        unsigned height : 5;
        unsigned spine  : 5 = 15 + memberID;
        for ( height : 0 .. 4 )
        {
            d_step
            {
                 attackerKnowledge = (  attackerKnowledge | ( 1 << (  spine  ) ) );
                spine = (spine - 1) / 2;
            }
        }
    };

    attacker_check_knowledge ( );
}


inline attacker_learn_root ( )
{
    StampBit ( attackerKnowledge, 0 );
    attacker_check_knowledge ( );
}



     
inline attacker_study_message ( memberID )
{
    // Logic of 15 vertices
    d_step // MISS!
    {
        unsigned n : 5;
        for ( n : 0 .. 15 )
        {
            unsigned v : 5 = 15 + n;
            if
            :: v != 15 + memberID && CheckBit ( attackerKnowledge, v ) && CheckBit ( membership, n ) -> StampBit ( attackerKnowledge, v )
            :: else -> ClearBit ( attackerKnowledge, v )
            fi
        }
    }

    d_step // MISS!
    {
        // Logic of internal vertices
        unsigned height : 5;
        unsigned offset : 5 = 15 / 2;
        unsigned width  : 5 = ( ( 31 / 2 ) + 1 ) / 2;
        for ( height : 0 + 1 .. 4 )
        {
            d_step
            {
                unsigned nn : 5;
                for ( nn : 0 .. width - 1 )
                {
                    unsigned v : 5 = offset + nn;
                    d_step
                    {
                        unsigned childL : 5 = v + v + 1;
                        unsigned childR : 5 = v + v + 2;
                        if
                        :: ( (  attackerKnowledge & ( 1 << (  childL  ) ) ) != 0 ) || ( (  attackerKnowledge & ( 1 << (  childR  ) ) ) != 0 ) ->  attackerKnowledge = (  attackerKnowledge | ( 1 << (  v  ) ) )
                        :: else ->  attackerKnowledge = (  attackerKnowledge & ( ~ ( 1 << (  v  ) ) ) )
                        fi
                    }
                };
                offset = offset / 2;
                width  = width  / 2;
            }
        }
    }

    print_attacker_knowledge ( );

    attacker_check_knowledge ( );
}


inline print_attacker_knowledge ( )
{
    d_step // MISS!
    {
        printf ( "\n\tAttacker Knowledge:" );
        d_step
        {
            printf ( "\n\t  ---\t-----\t---" );
            unsigned d : 5 = 2;
            unsigned v : 5;
            for ( v : 0 .. 30 )
            {
                if
                :: ( v + 1 ) == d ->
                    printf ( "\n\t  ---\t-----\t---" );
                    if
                    :: d < 16 -> d = d + d;
                    :: else
                    fi
                :: else
                fi

                if
                :: ( (  attackerKnowledge & ( 1 << (  v  ) ) ) != 0 ) -> printf ( "\n\t  %d [\tTrue \t]", v )
                :: else                             -> printf ( "\n\t  %d [\tFalse\t]", v )
                fi
            }
            printf ( "\n\t  ---\t-----\t---" );
            printf ( "\n" );
        }
    }
}



     


inline attacker_check_knowledge ( )
{
    if
    :: ( (  attackerKnowledge & ( 1 << (  0  ) ) ) != 0 ) -> learnedActiveKey = true;
    :: else -> skip
    fi
}



  






         


inline select_from ( options, selected )
{
    atomic
    {
        if
        :: options == 0 -> printf ( "\n-=-=-=-=-=-=-\nSelection Options = NONE!\n-=-=-=-=-=-=-=-\n" );
        :: else -> skip
        fi
        
        selected = 31;
        BITARRAY ( count );
        PopCount ( options, count );
//        printf ( "\nCount:\t%d", count );
        if
        :: count == 0 -> skip; // Leave ID as 31!
        :: else ->
            unsigned sample : 5;
            select ( sample : 0 .. count - 1 );
                unsigned n : 5 = 0;
                do
                :: selected != 31 -> break
                :: else ->
                    if
                    :: !( CheckBit ( options, n ) ) -> skip
                    :: else ->
                        if
                        :: sample == 0 -> selected = n
                        :: sample != 0 -> sample--
                        fi
                    fi
                    n++;
                od
        fi
    }
}


inline buffer_for_corrupt ( buffer )
{
    buffer = ( ~memberKeys ) & membership;
}


inline buffer_for_hoard ( buffer )
{
    buffer = ( ~( hoardPrior | hoardNovel ) ) & membership;
}


inline buffer_for_invitee ( buffer )
{
    BITARRAY ( most ) = widestID;
    if
    :: most < 16 - 1 -> most++
    :: else
    fi

    buffer = (1 << ( most + 1 )) - 1

// Debugging information output:
//    printf( "\nwidestID  :\t%d", widestID   );
//    printf( "\nMembership:\t%d", membership );
//    printf( "\nMost      :\t%d", most       );
//    printf( "\nBuffer[0] =           %d              = 0x%x"  , most,           most              );
//    printf( "\nBuffer[0] =         ( %d + 1 )        = 0x%x"  , most,         ( most + 1 )        );
//    printf( "\nBuffer[0] =   (1 << ( %d + 1 ))       = 0x%x"  , most,   (1 << ( most + 1 ))       );
//    printf( "\nBuffer[0] = ( (1 << ( %d + 1 )) - 1 ) = 0x%x"  , most, ( (1 << ( most + 1 )) - 1 ) );
//    printf( "\nBuffer[1] =          ~0x%x   = 0x%x"  ,         most,          ( ~membership ) );
//    printf( "\nBuffer[1] = 0x%d & ( ~0x%x ) = 0x%x\n", buffer, most, buffer & ( ~membership ) );

    buffer = buffer & ( ~membership )
}


inline select_corrupted ( )
{
    buffer = ( ~memberKeys ) & membership;
    select_from ( buffer, targetID );
}


inline select_evictor ( )
{
    buffer = membership;
     buffer = (  buffer & ( ~ ( 1 << (  targetID  ) ) ) );
    select_from ( buffer, originID );
}


inline select_evictee ( )
{
    buffer = membership;
    select_from ( buffer, targetID );
}


inline select_hoarder ( )
{
    buffer_for_hoard( buffer );
    select_from ( buffer, targetID );
}


inline select_invitee ( )
{
    buffer = membership;
    buffer_for_invitee( buffer );
    select_from ( buffer, targetID );
}


inline select_inviter ( )
{
    buffer = membership;
    select_from ( buffer, originID );
}


inline select_updater ( )
{
    buffer = membership;
    select_from ( buffer, originID );
}









         


inline corrupt ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( COR : @ %d <- _ )\n> > >\n", targetID );

move_corrupt:
    atomic
    {
        if
        :: ( (  hoardPrior & ( 1 << (  targetID  ) ) ) != 0 ) -> learnedLegacyKey = true;
        :: else
        fi

         memberKeys = (  memberKeys | ( 1 << (  targetID  ) ) );
        attacker_learn_leaf ( targetID );
    }
}


inline hoard ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( HRD : @ %d <- _ )\n> > >\n", targetID );

     hoardNovel = (  hoardNovel | ( 1 << (  targetID  ) ) )
}


inline reveal ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( RVL : * _ -- _ ) \n> > >\n" );

    challenged = true;
    learnedActiveKey = true;
    attacker_learn_root ( );
}



         


inline insert_member ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( ADD : + %d <- %d )\n> > >\n", targetID, originID );

    if
    :: targetID > widestID -> widestID = targetID
    :: else
    fi
     membership = (  membership | ( 1 << (  targetID  ) ) )
    attacker_study_message ( originID );
}


inline remove_member ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( RMV : - %d <- %d )\n> > >\n", targetID, originID );

     memberKeys = (  memberKeys & ( ~ ( 1 << (  targetID  ) ) ) );
     membership = (  membership & ( ~ ( 1 << (  targetID  ) ) ) );
    attacker_study_message ( originID );
}


inline oblige_update ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( UPD : @ _ <- %d )\n> > >\n", originID );

     memberKeys = (  memberKeys & ( ~ ( 1 << (  originID  ) ) ) );
    attacker_study_message ( originID );
}








         


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
        unsigned p : 5;
        for ( p : 0 .. 15 )
        {
            if
            :: ( (  membership & ( 1 << (  p  ) ) ) != 0 ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
            :: else                      -> printf ( "\n\t  %d [\tFalse\t]", p )
            fi
        };
        printf ( "\n" );
    }
}


inline print_user_hoarding ( )
{
    d_step {
        unsigned p : 5;
        
        printf ( "\n\tHoarding Prior:" );
        for ( p : 0 .. 15 )
        {
            if
            :: ( (  hoardPrior & ( 1 << (  p  ) ) ) != 0 ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
            :: else                      -> printf ( "\n\t  %d [\tFalse\t]", p )
            fi
        }
        printf ( "\n" );

        printf ( "\n\tHoarding Newly:" );
        for ( p : 0 .. 15 )
        {
            if
            :: ( (  hoardNovel & ( 1 << (  p  ) ) ) != 0 ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
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
        unsigned p : 5;
        for ( p : 0 .. 15 )
        {
            if
            :: ( (  memberKeys & ( 1 << (  p  ) ) ) != 0 ) -> printf ( "\n\t  %d [\tTrue\t]" , p )
            :: else                      -> printf ( "\n\t  %d [\tFalse\t]", p )
            fi
        }
        printf ( "\n" );
    }
}



         


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







         



         


inline CGKA_initialize ( )
{   atomic {
    d_step
    {
        printf( "\n***********************\n* CGKA: Initialize!   *\n***********************\n");

        hoardPrior = 0;
        memberKeys = 0;
        learnedActiveKey = false;

        attacker_initialize ( )
    };

}   }


inline CGKA_create_group ( )
{
    // Number of members to add
    unsigned sample : 5;
    select ( sample : 2 .. 16 );
    skip;
    d_step
    {
        unsigned n : 5;
        for ( n : 0 .. sample - 1 )
        {
             membership = (  membership | ( 1 << (  n  ) ) )
        };
        widestID = sample - 1;
    };

    printf( "\n***********************\n* CGKA: Create Group! *\n***********************\n" );

    print_membership ( );
}


inline CGKA_security_game ( )
{
    printf( "\n***********************\n* CGKA: Begin Play!   *\n***********************\n" );

    bool finished = false;
    unsigned nonCommitmentOptions : 3 = 7;

    // Loop through all possible epochs up to parameter `T`.
    // Stop at some `t` in range `[ 0, T - 1 ]` by querying "Challenge" oracle.
    // Non-deterministically explores epoch sequences:
    //   - { 0 }
    //   - { 0, 1 }
    //   - { 0, 1, 2 }
    //   - ...
    //   - { 0, 1, ... , T - 1 }

    // Each time the attacker takes a turn, they must decide whether or not to:
    //
    //   1. End the game; under the assumption that the attacker has won.
    //   2. Play a move which will *commit* the group members to advance to the next epoch
    //   3. Play a move which where the group members remain in the current epoch
    //
    // We call selection the options "challenge," "commitment," and "non-committal" moves, respectively.

start_of_game: skip;
    do
    :: finished -> break
    :: else ->

start_of_epoch:
        {
            printf ( "\n\n> > >\tStarting Epoch\n\n" );
            BITARRAY ( buffer     ) = 0;
            BITARRAY ( hoardNovel ) = 0;
            bool challenged = false;

            do

            // 1. Play the Challenge Move
            //     The attacker ending the game is the last move of the model.
            //     This is done by querying the 'challenge' oracle.
            //     *MAY*  query 'challenge' oracle in any epoch before last epoch.
            //     *MUST* query 'challenge' oracle in the last epoch.
            //     so it always happens in the last epoch.
            :: !(challenged) ->
aborting_epoch: { finished = true; break };

            // 2. Play a Non-commital Move
            //     The attacker *may* play a move and remain in the same epoch...
            //     unless the attacker has exhausted all idempotent non-comittal moves!
            :: nonCommitmentOptions != 0 ->
continue_epoch: { play_move_without_commitment ( ) };

            // 3. Play a Commitment Move
            //     The attacker *may* play a move which commits to a new epoch...
            //     unless it is the last epoch.
            :: true ->
advanced_epoch: { play_move_with_commitment ( ); break };

            od;

            printf ( "\n> > >\tEnding Epoch\n\n" );
            post_epoch_update ( );
        };
    od;

end_of_game: skip
}



         


inline play_move_with_commitment ( )
{
    buffer = membership;
    PopCount ( buffer, buffer );
    printf ( "\n\tAttendees:\t%d", buffer );

    if
    :: buffer != 16 -> atomic { select_invitee ( ); select_inviter ( ); insert_member ( ) }
    :: buffer >  2 -> atomic { select_evictee ( ); select_evictor ( ); remove_member ( ) }
    :: true        -> atomic {                     select_updater ( ); oblige_update ( ) }
    fi

    post_move_update ( );
}



     
inline play_move_without_commitment ( )
{
    if
    :: CheckBit ( nonCommitmentOptions, 0 ) -> { select_corrupted ( ); corrupt ( ) }
    :: CheckBit ( nonCommitmentOptions, 1 ) -> { select_hoarder   ( ); hoard   ( ) }
    :: CheckBit ( nonCommitmentOptions, 2 ) -> {                       reveal  ( ) }
    fi

    post_move_update ( );
}



         



     
inline post_epoch_update ( )
{
    d_step
    {
        // After the operation is complete, check to see if the an endgame condition has been reached.
        printf( "\nLOOP broken!" );


  
        // Reset the challenge bit
        challenged = false;

        // Re-check if the reveal oracle can be queried
        check_query_reveal ( );

        // Merge new hoarders into accumulator for next epoch
        hoardPrior = hoardPrior | hoardNovel;

        print_entire_state ( );
    }
}



     
inline post_move_update ( )
{
    d_step
    {
        // Unset the "active IDs"
        originID = 31;
        targetID = 31;

        // Determine if non-commitment is an option, or if commitment is forced
        //
        // Commitment is not forced if and only if one or more is true:
        //   * Can Corrupt Member
        //   * Can Hoard Member
        //   * Can Reveal Root
        nonCommitmentOptions = 0;
        buffer = 0;

        // Check if "Can Corrupt Member"
        buffer_for_corrupt ( buffer );
        PopCount ( buffer, buffer );
        if
        :: buffer > 0 -> StampBit ( nonCommitmentOptions, 0 )
        :: else
        fi

        // Check if "Can Hoard Member"
        buffer_for_hoard ( buffer );
        PopCount ( buffer, buffer );
        if
        :: buffer > 0 -> StampBit ( nonCommitmentOptions, 1 )
        :: else
        fi

        check_query_reveal ( );

        printf ( "\n\tNon-Commitment Options:\t[ %d, %d, %d ]\n", CheckBit (nonCommitmentOptions, 0), CheckBit (nonCommitmentOptions, 1), CheckBit (nonCommitmentOptions, 2) );
    }
}



     
inline check_query_reveal ( )
{
    if
    :: !( challenged || learnedActiveKey ) -> StampBit ( nonCommitmentOptions, 2 )
    :: else -> ClearBit ( nonCommitmentOptions, 2 )
    fi
}


active proctype CGKA ( )
{
    CGKA_initialize    ( );
    CGKA_create_group  ( );
    CGKA_security_game ( );
}





     
ltl PCS
{

[] ( ( CGKA@start_of_epoch && ( memberKeys == 0 ) ) -> ( !( learnedActiveKey ) ) )


}


