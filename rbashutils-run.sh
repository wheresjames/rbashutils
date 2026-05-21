#!/bin/bash

USAGE="Usage: ${BASH_SOURCE[0]} <command>"

ROOTDIR="${BASH_SOURCE%/*}"
if [[ ! -d "$ROOTDIR" ]]; then ROOTDIR="$PWD"; fi
. "${ROOTDIR}/rbashutils.sh"
. "${ROOTDIR}/rbashutils-code.sh"

COMMANDLIST=$1
setCmd "$COMMANDLIST"

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

if isCmd "check"; then

    showInfo "Checking shell syntax..."
    bash -n "${ROOTDIR}/rbashutils.sh" \
            "${ROOTDIR}/rbashutils-web.sh" \
            "${ROOTDIR}/rbashutils-sys.sh" \
            "${ROOTDIR}/rbashutils-code.sh" \
            "${ROOTDIR}/rbashutils-run.sh" \
            "${ROOTDIR}/rbashutils-test.sh"
    exitOnError "bash syntax check failed"

    if command -v shellcheck >/dev/null 2>&1; then
        showInfo "Running shellcheck..."
        shellcheck "${ROOTDIR}/rbashutils.sh" \
                   "${ROOTDIR}/rbashutils-web.sh" \
                   "${ROOTDIR}/rbashutils-sys.sh" \
                   "${ROOTDIR}/rbashutils-code.sh" \
                   "${ROOTDIR}/rbashutils-run.sh" \
                   "${ROOTDIR}/rbashutils-test.sh"
        exitOnError "shellcheck failed"
    else
        showNotice "shellcheck not installed, skipping"
    fi

    if command -v shfmt >/dev/null 2>&1; then
        showInfo "Running shfmt diff..."
        shfmt -d "${ROOTDIR}/rbashutils.sh" \
                 "${ROOTDIR}/rbashutils-web.sh" \
                 "${ROOTDIR}/rbashutils-sys.sh" \
                 "${ROOTDIR}/rbashutils-code.sh" \
                 "${ROOTDIR}/rbashutils-run.sh" \
                 "${ROOTDIR}/rbashutils-test.sh"
        exitOnError "shfmt check failed"
    else
        showNotice "shfmt not installed, skipping"
    fi

    doExit 0
fi
