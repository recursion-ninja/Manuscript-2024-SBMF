#!/bin/bash

MINDFA=24
VECLEN=65

# 12 GiB = 12288 MiB
# 18 GiB = 18432 MiB
# 24 GiB = 24576 MiB
DIRECTIVE_DEFAULTS=(
#    'FULL_TRAIL'
    'SC'    
    'JOINPROCS'
    'MEMLIM=24576'
    'MURMUR'
    'NOBOUNDCHECK'
    'NOFIX'
#    'PRINTF'
    'SEPQS'
    'SFH'
    "VECTORSZ=${VECLEN}"
#    'VAR_RANGES'
)

DIRECTIVE_STRATEGY_FULL=(
    "COLLAPSE"
    "MA=${MINDFA}"
)
DIRECTIVE_STRATEGY_HASH=(
    "HC4"
    "SPACE"
)

# A POSIX variable
# Reset in case getopts has been used previously in the shell.
OPTIND=1

# Initialize our own variables:
USE_HASH=0
USE_CPP=0

while getopts "hc" opt; do
  case "$opt" in
      c) USE_CPP=1 ;;
      h) USE_HASH=1 ;;
  esac
done

shift $((OPTIND-1))

if [[ "${USE_CPP}" -eq "0" ]]; then
    BASENAME_VALUE="Model-of-CGKA-Security-Game"
else
    BASENAME_VALUE="Model-Concat"
fi

if [[ "${USE_HASH}" -eq "0" ]]; then
    FLAG_STRATEGY="${DIRECTIVE_STRATEGY_FULL[@]/#/-D}"
else
    FLAG_STRATEGY="${DIRECTIVE_STRATEGY_HASH[@]/#/-D}"
fi

FILEPATH_DIARY="${BASENAME_VALUE}.log"
FILEPATH_MODEL="${BASENAME_VALUE}.pml"
FILEPATH_TRAIL="${BASENAME_VALUE}.trail"
TEMPLATE_MERGE="${BASENAME_VALUE}-XXXX.txt"

FLAG_DEFAULTS=("${DIRECTIVE_DEFAULTS[@]/#/-D}")
FLAG_COMPLETE="${FLAG_DEFAULTS[@]} ${FLAG_STRATEGY[@]}"

NAME_BINARY="${BASENAME_VALUE}"

if [[ -z "${FLAG_COMPLETE}" ]]; then
    FLAG_RENDERED="{} (Empty Set)"
else
    FLAG_RENDERED="{ $(echo -e "${FLAG_COMPLETE}" | sed -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+/, /g') }"
fi

# Clean up
rm -f "${FILEPATH_TRAIL}"

echo -e "Building model with directive set:\n\t${FLAG_RENDERED}"

# Pre-process and merge the model source files
if [[ "${USE_CPP}" -eq "0" ]]; then
    printf "Pre-processing and merging sources... "
    head -n 8 CGKA-Security-Game.pml > "${FILEPATH_MODEL}"
    tail -n+8 CGKA-Security-Game.pml | cpp -P CGKA-Security-Game.pml >> "${FILEPATH_MODEL}"
#    sed -i'.bak' 's/^#\s[^\n]\+$//g' "${FILEPATH_MODEL}"
#    sed -i'.bak' 'N;/^\n$/d;P;D' "${FILEPATH_MODEL}"
    printf "\tdone!\n"
fi

# Transpile model
spin -a "${FILEPATH_MODEL}"

# Patch the header file
printf "Patching header missing include... "
FILEPATH_MERGE=$(mktemp -t "${TEMPLATE_MERGE}")
echo "#include <stdio.h>" > "${FILEPATH_MERGE}"
cat pan.h >> "${FILEPATH_MERGE}"
mv "${FILEPATH_MERGE}" pan.h
printf "\tdone!\n"

# Compile the model's program analysis executable
printf "Compiling model to program analysis... "
gcc \
    ${FLAG_COMPLETE} \
    -O3 \
    -o "${NAME_BINARY}" \
    pan.c
printf "\tdone!\n"

printf "Analysing model for selected properties...\n"
chmod +x "${NAME_BINARY}"
#/usr/bin/time -f "\n\ntime:\n\tElapsed time: %es\n\tMemory usage: %M KB\n\tCPU usage: %P\n\n" ./"${NAME_BINARY}" -A -v -x | tee "${FILEPATH_DIARY}"

# Search depth set to 10,000,000 (default 10,000)
INVOCATION_OPTIONS=(
    -a
    -A
    -m1000000
    -v
    -w30
    -x
)

./"${NAME_BINARY}" "${INVOCATION_OPTIONS[@]}" -N FSU
#./"${NAME_BINARY}" "${INVOCATION_OPTIONS[@]}" -N PCS

#/usr/bin/time -f "DIRECTIVE: ${FLAG_ELECTION}\n\tElapsed time: %es\n\tMemory usage: %M KB\n\tCPU usage: %P\n\n${FLAG_ELECTION}\t%e\t%M\n\n" "./${NAME_BINARY}" -a -A -v -x
#
