#ifndef IMPORT_SPEC_ATTACKER
#define IMPORT_SPEC_ATTACKER


#include "Parameterized-Constants.pml"
#include "Global-State.pml"


/****
  *
  * Attacker's protocol specific knowledgebase.
  *
  * +=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+
  * |                                   |
  * |  PROTOCOL: TreeKEM Version 1.0.0  |
  * |                                   |
  * +=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=+
  *
****/


/****
  *
  * Any TreeKEM "module" version must export the following "inline" definitions:
  *
  * Exports:
  *   - attacker_initialize
  *   - attacker_learn_leaf
  *   - attacker_learn_root
  *   - attacker_study_message
  *   - print_attacker_knowledge
  *   - attacker_amend_knowledge
  *
  * The exported definitions correspond to how the attacker observes, stores,
  * and updates knowledge about the TreeKEM protocol's LBBT of secret keys.
  * The goal of the attacker is to know the value of the shared secret symmetric
  * key stored at the root node.
  *
  * The definitions are used by the:
  *   - CGKA security game control flow
  *   - CGKA Oracles
  *
****/


/****
  *
  * The attacker knowledgebase represents the TreeKEM (version 1) LBBT as a heap.
  *
  * Observe the following example LBBT heap representation of for (N = 8):
  *
  *     Left-balanced Binary Tree Topology:
  *    
  *                +-----(14)-----+
  *               /                \
  *             (12)              (13)
  *            /    \            /    \
  *         (8)     (9)       (10)     (11)
  *        /   \   /   \     /    \   /    \
  *       0     1 2     3   4      5 6      7 
  *     
  *     Binary Heap Layout:
  *     
  *       Index:   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14
  *       Array: [  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ]
  *       Nodes:  14  12  13   8   9  10  11   0   1   2   3   4   5   6   7
  *
  *
  * Similarly for (N = 4):
  *
  *     Left-balanced Binary Tree Topology:
  *    
  *             (6)
  *            /    \
  *         (4)     (5)
  *        /   \   /   \
  *       0     1 2     3
  *     
  *     Binary Heap Layout:
  *     
  *       Index:   0   1   2   3   4   5   6
  *       Array: [  ][  ][  ][  ][  ][  ][  ]
  *       Nodes:   6   4   5   0   1   2   3
  *
  *
  * The N parameter defines size of LBBT in heap layout:
  *
  *    - (N <=  4) --> TREE_ORDER <=  7
  *    - (N <=  8) --> TREE_ORDER <= 15
  *    - (N <= 16) --> TREE_ORDER <= 31
  *
  * Hence, the Promela dataypes 'byte', 'short', and 'int' are respectively used
  * to endode the binary LBBT vertex knowledge as a "bit-array."
  *
****/
#if    N <=  4
#define KNOWLEDGE_DATATYPE byte

#elif  N <=  8
#define KNOWLEDGE_DATATYPE short

#elif  N <= 16
#define KNOWLEDGE_DATATYPE int

#else
#error N must be in range [2, 16]
#endif


/****
  *
  * The attacker knowledgebase must track knowledge over time, as information
  * from a past epoch could be learned and effect the attacker's knowledge of
  * subsequent epochs. Consequently the attacker knowledgebase is represented
  * as an array of heaps.
  *
****/
KNOWLEDGE_DATATYPE attackerKnowledge;


/****
  *
  * Export inline definitions for:
  *   - attacker_initialize
  *   - attacker_learn_leaf
  *   - attacker_learn_root
  *   - attacker_study_message
  *   - print_attacker_knowledge
  *
****/


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
//    StampBit ( attackerKnowledge, LEAF + memberID );
//    attacker_spine_from ( memberID );
/**/
    d_step
    {
        unsigned height : BITS_VERTEX;
        unsigned spine  : BITS_VERTEX = LEAF + memberID;
        for ( height : LEAF_LEVEL .. ROOT_LEVEL )
        {
            d_step
            {
                StampBit( attackerKnowledge, spine );
                spine = (spine - 1) / 2;
            }
        }
    };
/**/
    attacker_check_knowledge ( );
}


inline attacker_learn_root ( )
{
    StampBit ( attackerKnowledge, ROOT );
    attacker_check_knowledge ( );
}


/****
  *
  * Propogates knowledge from epoch 'e' to 'e+1'.
  * Notes the member ID who initiated the epoch from 'leadership'.
  * Ensures that knowledge (if any) of the initiating member secrets does not propogate
  *
****/
inline attacker_study_message ( memberID )
{
    // Logic of LEAF vertices
    d_step // MISS!
    {
        unsigned n : BITS_VERTEX;
        for ( n : FIRST_USERID .. FINAL_USERID )
        {
            unsigned v : BITS_VERTEX = LEAF + n;
            if
            :: v != LEAF + memberID && CheckBit ( attackerKnowledge, v ) && CheckBit ( membership, n ) -> StampBit ( attackerKnowledge, v )
            :: else -> ClearBit ( attackerKnowledge, v )
            fi
        }
    }

    d_step // MISS!
    {
        // Logic of internal vertices
        unsigned height : BITS_VERTEX;
        unsigned offset : BITS_VERTEX = LEAF / 2;
        unsigned width  : BITS_VERTEX = ( ( TREE_ORDER / 2 ) + 1 ) / 2;
        for ( height : LEAF_LEVEL + 1 .. ROOT_LEVEL )
        {
            d_step
            {
                unsigned nn : BITS_VERTEX;
                for ( nn : 0 .. width - 1 )
                {
                    unsigned v : BITS_VERTEX = offset + nn;
                    d_step
                    {
                        unsigned childL : BITS_VERTEX = v + v + 1;
                        unsigned childR : BITS_VERTEX = v + v + 2;
                        if
                        :: CheckBit( attackerKnowledge, childL ) || CheckBit( attackerKnowledge, childR ) -> StampBit( attackerKnowledge, v )
                        :: else -> ClearBit( attackerKnowledge, v )
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
            unsigned d : BITS_VERTEX = 2;
            unsigned v : BITS_VERTEX;
            for ( v : FIRST_VERTEX .. FINAL_VERTEX )
            {
                if
                :: ( v + 1 ) == d ->
                    printf ( "\n\t  ---\t-----\t---" );
                    if
                    :: d < N -> d = d + d;
                    :: else
                    fi
                :: else
                fi

                if
                :: CheckBit( attackerKnowledge, v ) -> printf ( "\n\t  %d [\tTrue \t]", v )
                :: else                             -> printf ( "\n\t  %d [\tFalse\t]", v )
                fi
            }
            printf ( "\n\t  ---\t-----\t---" );
            printf ( "\n" );
        }
    }
}


/****
  *
  * Internal inline definition:
  *   - attacker_check_knowledge
  *   - attacker_relay_knowledge
  *
****/


inline attacker_check_knowledge ( )
{
    if
    :: CheckBit( attackerKnowledge, ROOT ) -> learnedActiveKey = true;
    :: else -> skip
    fi
}


/*
inline attacker_spine_from ( memberID )
{
    d_step
    {
        unsigned height : BITS_VERTEX = LEAF_LEVEL + 1;
        unsigned spine  : BITS_VERTEX = LEAF + memberID;
        spine = (spine - 1) / 2;
        
        do
        :: height >= ROOT_LEVEL || CheckBit( attackerKnowledge, spine ) -> break
        :: else ->
            {
                StampBit( attackerKnowledge, spine );
                spine = (spine - 1) / 2;
                height++;
            }
        od
    }
}
*/


#endif /* IMPORT_SPEC_ATTACKER */ 