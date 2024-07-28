#include "Parameterized-Constants.pml"
#include "Bit-Array.pml"
#include "Pop-Count.pml"
#include "Selection.pml"
#include "Oracles.pml"
#include "Printing.pml"
#include "Global-State.pml"


/********
    *
    * Safety Predicate (Triviality):
    *
    * Consider the following succession of attacker moves in the CKGA game.
    * We will call each move a "query," as to remain in line with the literature.
    * The attacker performs a non-empty sequence of queries to the oracles.
    * The sequence then ends with an additional query to a special "challenge" oracle.
    * By construction the sequence has at least 2 queries.
    *
    * Consider the function
    *     whichEpoch(q) : query -> Natural
    * This function returns the epoch during which the query was made.
    *
    * Now consider the array `Q` containing the sequence of queries.
    *
    *     triviality ( Q ):
    *         for  (i,j) s.t. Q[i] = corrupt(ID) and Q[j] = challenge
    *             if
    *                 whichEpoch(Q[i]) <= whichEpoch(Q[j]) AND there does not exist `k` s.t.
    *                     0 < whichEpoch(Q[i]) < whichEpoch(Q[k]) <= whichEpoch(Q[j]) AND
    *                     Q[k] = update(ID) or Q[k] = remove(ID)
    *             then
    *                 return FALSE
    *             done
    *             if
    *                 which(Q[i]) > whichEpoch(Q[j]) AND there exists `k` s.t.
    *                   whichEpoch(Q[k]) <= whichEpoch(Q[j]) AND Q[k] = hoard(ID)
    *             then
    *                 return FALSE
    *             done
    *         end
    *         return TRUE
    *
    * This predicate is described as the "Safety Predicate" `safe` in Alwen 2020.
    * We use `triviality` as a synonym from `safe` because the term "safety predicate has
    * a different connotation in  formal methods nomenclature.
    *
********/


/********
    *
    * Initialization inline routines, in order of execution:
    *
    *   - Initialize
    *   - Select Group
    *   - Create Group
    *   - CGKA Security Game
    *
********/


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
    unsigned sample : BITS_USERID;
    select ( sample : 2 .. N );
    skip;
    d_step
    {
        unsigned n : BITS_USERID;
        for ( n : FIRST_USERID .. sample - 1 )
        {
            StampBit( membership, n )
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


/********
    *
    * Adversary moves interacting with oracles:
    *
    *   - play_move_with_commitment
    *   - play_move_without_commitment
    *
********/


inline play_move_with_commitment ( )
{
    buffer = membership;
    PopCount ( buffer, buffer );
    printf ( "\n\tAttendees:\t%d", buffer );

    if
    :: buffer != N -> atomic { select_invitee ( ); select_inviter ( ); insert_member ( ) }
    :: buffer >  2 -> atomic { select_evictee ( ); select_evictor ( ); remove_member ( ) }
    :: true        -> atomic {                     select_updater ( ); oblige_update ( ) }
    fi

    post_move_update ( );
}


/****
  *
  * Adversary moves without advancing the epoch via one of the following oracles:
  *
  *   - Corrupt
  *   - Hoard
  *   - Reveal
  *
****/
inline play_move_without_commitment ( )
{
    if
    :: CheckBit ( nonCommitmentOptions, 0 ) -> { select_corrupted ( ); corrupt ( ) }
    :: CheckBit ( nonCommitmentOptions, 1 ) -> { select_hoarder   ( ); hoard   ( ) }
    :: CheckBit ( nonCommitmentOptions, 2 ) -> {                       reveal  ( ) }
    fi

    post_move_update ( );
}


/********
    *
    * Updating functions:
    *
    *   - post_epoch_update
    *   - post_move_update
    *
********/


/****
  * External result variable(s):
  *   - challenged
  *   - hoardPrior
  *   - nonCommitmentOptions
****/
inline post_epoch_update ( )
{
    d_step
    {
        // After the operation is complete, check to see if the an endgame condition has been reached.
        printf( "\nLOOP broken!" );

/*
        // Check if the largest member ID has increased
        // BUT, not over the maximum value of N - 1
        if
        :: widestID < N - 1 ->
            {
                buffer = membership;
                ClearBit( buffer, widestID );
                if
                :: buffer > widestID -> widestID++
                :: else
                fi
            }
        :: else
        fi
*/
        // Reset the challenge bit
        challenged = false;

        // Re-check if the reveal oracle can be queried
        check_query_reveal ( );

        // Merge new hoarders into accumulator for next epoch
        hoardPrior = hoardPrior | hoardNovel;

        print_entire_state ( );
    }
}


/****
  * External result variable(s):
  *   - nonCommitmentOptions
  *   - originID
  *   - targetID
****/
inline post_move_update ( )
{
    d_step
    {
        // Unset the "active IDs"
        originID = NONE;
        targetID = NONE;

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


/****
  *
  *  Check if adversary can query the "Reveal" oracle
  *
****/
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


#if LTL_PROPERTY_HLT == 1

/****
  *
  * LTL: HLT (Halt / Decidablity)
  *
  * The model always terminates.
  *
****/
ltl HLT
{
#include "LTL-HLT.pml"
}

#endif
#if LTL_PROPERTY_FSU == 1

/****
  *
  * LTL: FSU (Future Secrecy with Updates)
  *
  * Never corrupt a hoarder implies never learn the past
  *
****/
ltl FSU
{
#include "LTL-FSU.pml"
}

#endif
#if LTL_PROPERTY_PCS == 1

/****
  *
  * LTL: PCS (Post-Compromise Security)
  *
****/
ltl PCS
{
#include "LTL-PCS.pml"
}

#endif
