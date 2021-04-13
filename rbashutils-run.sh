#!/bin/bash

USAGE="Usage: ${BASH_SOURCE[0]} <command>"

ROOTDIR="${BASH_SOURCE%/*}"
if [[ ! -d "$ROOTDIR" ]]; then ROOTDIR="$PWD"; fi
. "${ROOTDIR}/rbashutils.sh"
. "${ROOTDIR}/rbashutils-code.sh"

COMMANDLIST=$1
setCmd $COMMANDLIST

#----------------------------------------------------------
echo
showVars '-' COMMANDLIST BASH_SOURCE ROOTDIR

if isCmd "install"; then

    if isCmd "cmake"; then

        showInfo "Installing cmake..."

        installCMake

    fi

    doExit 0
fi

