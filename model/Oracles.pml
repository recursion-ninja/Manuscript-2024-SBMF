#ifndef IMPORT_SPEC_ORACLES
#define IMPORT_SPEC_ORACLES

#include "Parameterized-Constants.pml"
#include "Global-State.pml"

#ifdef PROTOCOL_VERSION
#if PROTOCOL_VERSION == 2
#include "TreeKEM-v2.pml"
#endif
#else
#include "TreeKEM-v1.pml"
#endif

/********
    *
    * Oracles available to the attacker used by "non-commital" moves:
    *
    *   - Corrupt ( COR )
    *   - Hoard   ( HRD )
    *   - Reveal  ( RVL )
    *
********/


inline corrupt ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( COR : @ %d <- _ )\n> > >\n", targetID );

move_corrupt:
    atomic
    {
        if
        :: CheckBit( hoardPrior, targetID ) -> learnedLegacyKey = true;
        :: else
        fi

        StampBit( memberKeys, targetID );
        attacker_learn_leaf ( targetID );
    }
}


inline hoard ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( HRD : @ %d <- _ )\n> > >\n", targetID );

    StampBit( hoardNovel, targetID )
}


inline reveal ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( RVL : * _ -- _ ) \n> > >\n" );

    challenged = true;
    learnedActiveKey = true;
    attacker_learn_root ( );
}


/********
    *
    * Oracles available to the attacker used by "commitment" moves:
    *
    *   - Insert Member ( ADD )
    *   - Remove Member ( RMV )
    *   - Oblige Update ( UPD )
    *
********/


inline insert_member ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( ADD : + %d <- %d )\n> > >\n", targetID, originID );

    if
    :: targetID > widestID -> widestID = targetID
    :: else
    fi
    StampBit( membership, targetID )
    attacker_study_message ( originID );
}


inline remove_member ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( RMV : - %d <- %d )\n> > >\n", targetID, originID );

    ClearBit( memberKeys, targetID );
    ClearBit( membership, targetID );
    attacker_study_message ( originID );
}


inline oblige_update ( )
{
    printf ( "\n> > >\n> CGKA: Move Name\t( UPD : @ _ <- %d )\n> > >\n", originID );

    ClearBit( memberKeys, originID );
    attacker_study_message ( originID );
}


#endif /* IMPORT_SPEC_ORACLES */
