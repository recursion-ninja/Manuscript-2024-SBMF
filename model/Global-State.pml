#ifndef IMPORT_SPEC_GLOBALS
#define IMPORT_SPEC_GLOBALS


/********
  *
  * Advantage:
  *
  * In the following, a (`t`, `c`, `n`)-attacker is an attacker `A` that runs in time at most `t`,
  * makes at most `c` challenge queries, and never produces a group with more than `n` members.
  * The attacker wins the CGKA security game if they correctly guesses the random bit `b` in
  * the end and the safety predicate `P` evaluates to true on the queries made by the attacker.
  *
  * Parameters (`t`, `c`, `n`), are defined via pre-preocessor constants as the macro symbols
  * `T`, `C`, and `N`, along with derivative constants, in the following "#included" Promela file:
  *
********/

#include "Bit-Array.pml"
#include "Parameterized-Constants.pml"

/****
  *
  * Global state of the CGKA security game.
  *
****/

// 'Bit-Arrays' variables
local BITARRAY ( hoardPrior ); // Group membership of current epoch
local BITARRAY ( memberKeys ); // Members whose keys are known (corrupted), require an update/removal
local BITARRAY ( membership ); // Group membership of current epoch

// Scalar variables
local unsigned originID : BITS_USERID; // ID of the  member
local unsigned targetID : BITS_USERID; // ID of the effected member
local unsigned widestID : BITS_N;      // The maximum ID during any past/present epoch.

// Knowledge flags
local bool learnedActiveKey; // Attacker learned the group's shared secret key during the key's epoch?
local bool learnedLegacyKey; // Attacker learned the group's shared secret key after  the key's epoch?


#endif /* IMPORT_SPEC_GLOBALS */
