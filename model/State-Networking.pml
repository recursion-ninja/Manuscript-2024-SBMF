#ifndef IMPORT_SPEC_NETWORKING
#define IMPORT_SPEC_NETWORKING


#include "State-Global.pml"
#include "Parameterized-Constants.pml"
#include "TreeKEM-v1.pml"


/****
  *
  * Global state of derivative variables.
  *   (Each can is defined in terms of the CGKA global state variables)
  *
****/

// Group Composition
local unsigned attendees : BITS_USERID = N;
local unsigned absentees : BITS_USERID = 0;
local unsigned groupMost : BITS_USERID = 0; // The maximum member ID during any past/present epoch.

// Protocol State
local bool commitmentRequired = false;


/********
    *
    * Inline utilities for after move updates:
    *   - messaging_move
    *   - post_play_poll
    *
********/


/****
  *
  * The inline definition is used by the security game moves:
  *   - insert_member (Oracle ADD)
  *   - remove_member (Oracle RMV)
  *   - oblige_update (Oracle UPD)
  *
  * Modifies global variable(s):
  *   - abstract "attacker knowledgebase"
  *
****/
inline messaging_move ( e, inviter )
{
    leadership[e] = inviter;
    attacker_study_message ( e );
}


/****
  *
  * The inline definition is used by the security game moves:
  *   - remove_member (Oracle RMV)
  *   - oblige_update (Oracle UPD)
  *
****/
inline restore_safety ( id )
{
    d_step
    {
        if
        :: CheckBit( unsafe, id ) -> unsafeIDs--
        :: else
        fi
        ClearBit( unsafe, id );
    }
}


/****
  * External result variable(s):
  *   - commitmentRequired
  *   - unsafeIDs
****/
inline post_play_poll ( e )
{
    d_step {
        // Unset the "active IDs"
        originID = NONE;
        targetID = NONE;

        // Refresh "unsafeIDs"
        unsigned remainingEpochs    : BITS_EPOCH = FINAL_EPOCH - e;
        unsigned recoveriesRequired : BITS_USERID = 0;
        d_step
        {
            unsigned n : BITS_USERID;
            for ( n : FIRST_USERID .. FINAL_USERID ) {
                if
                :: CheckBit( unsafe, n ) -> recoveriesRequired++;
                :: else
                fi
            }
        }
        unsafeIDs = recoveriesRequired;
        
        bool canRevealRoot = e != FINAL_EPOCH && !( CheckBit( learnedKey, e ) );

        // Refresh "commitmentRequired"
        bool canHoardMember = false;
        d_step
        {
            unsigned candidateHoarders : BITS_USERID;
            candidates_for_hoarding ( );
            canHoardMember = candidateHoarders > 0;
        }
    
        bool canCorruptMember = false;
        d_step
        {
            unsigned candidateCorruptibles : BITS_USERID;
            candidates_for_corruption ( );
            canCorruptMember = candidateCorruptibles > 0;
        }
    
        commitmentRequired = !canRevealRoot && !canHoardMember && !canCorruptMember
    }
}


/****
  * External result variable(s):
  *   - absentees
  *   - attendees
  *   - groupMost
****/
inline take_attendance ( )
{
    unsigned largestID : BITS_USERID = 0;
    d_step {
        unsigned included : BITS_USERID = 0;
        d_step {
            unsigned n : BITS_USERID;
            for ( n : FIRST_USERID .. FINAL_USERID ) {
                 if
                 :: CheckBit( membership, n ) -> included++; largestID = n
                 :: else
                 fi
            }
        }
        attendees = included;
        absentees = N - attendees;
    }

    if
    :: largestID + 1 > groupMost -> groupMost = largestID + 1;
    :: else
    fi
}


/****
  * External result variable(s):
  *   - candidateCorruptibles
****/
inline candidates_for_corruption ( )
{
    unsigned candidates : BITS_USERID = 0;
    d_step
    {
        unsigned n : BITS_USERID;
        for ( n : FIRST_USERID .. FINAL_USERID )
        {
            bool candidateCorruption;
            candidate_corruption ( n );
            if
            :: candidateCorruption -> candidates++
            :: else
            fi
        }
    }
    candidateCorruptibles = candidates
}


/****
  * External result variable(s):
  *   - candidateCorruption
****/
inline candidate_corruption ( id )
{
    // The corrupted user must not previously been instructed to hoard!
    // Violates the "Safety Predicate SAFE" described in Alwen 2020.
    candidateCorruption = CheckBit( membership, id ) && !( CheckBit( attackerKnowledge[epoch], LEAF + id ) )
}


/****
  * External result variable(s):
  *   - candidateHoarders
****/
inline candidates_for_hoarding ( )
{
    unsigned candidates : BITS_USERID = 0;
    d_step
    {
        unsigned n : BITS_USERID;
        for ( n : FIRST_USERID .. FINAL_USERID )
        {
            bool candidateHoarder
            candidate_hoarder ( n );
            if
            :: candidateHoarder -> candidates++
            :: else
            fi
        }
    }
    candidateHoarders = candidates
}


/****
  * External result variable(s):
  *   - candidateHoarder
****/
inline candidate_hoarder ( id )
{
    candidateHoarder = hoarding[id] == NEVER && CheckBit( membership, id )
}


#endif /* IMPORT_SPEC_NETWORKING */
