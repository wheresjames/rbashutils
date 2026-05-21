#!/bin/bash

# Checkout git repo
# @param [in] string - Repo sub directory
# @param [in] string - Repo name
# @param [in] string - Repo url
# @param [in] string - Repo branch
# @param [in] string - [optional] Git tag
gitCheckoutOrUpdate()
{
    local PRJSUB=$1
    local PRJNAME=$2
    local PRJURL=$3
    local PRJBRANCH=$4
    local PRJGITTAG=$5

    local ORGPATH
    ORGPATH=$(pwd)

    if [ ! -d "${PRJSUB}" ]; then
        mkdir -p "${PRJSUB}"
        exitOnError "Failed to create directory: ${PRJSUB}"
    fi

    cd "${PRJSUB}"
    exitOnError "Failed to switch to directory: ${PRJSUB}"

    # Need checkout?
    if [ ! -d "${PRJNAME}" ]; then
        showInfo "Checking out: ${PRJNAME}"
        git clone "${PRJURL}" "${PRJNAME}"
        exitOnError "Failed to clone git repo: ${PRJURL}"
    fi

    # Update
    cd "${PRJNAME}"
    exitOnError "Failed to switch to repo directory: ${PRJNAME}"

    # Checkout branch
    if [ ! -z "$PRJBRANCH" ]; then
        showInfo "Switching to branch: ${PRJBRANCH}"
        git checkout "${PRJBRANCH}"
        exitOnError "Failed to checkout branch: ${PRJBRANCH}"
        git pull
        exitOnError "Failed to pull branch: ${PRJBRANCH}"
    fi

    # Tag repo
    if [ ! -z "$PRJGITTAG" ]; then
        showInfo "Tagging: ${PRJNAME} -> ${PRJGITTAG}"
        git tag "${PRJGITTAG}"
        warnOnError "Unable to tag git: ${PRJGITTAG}"
        git push origin "${PRJGITTAG}"
    fi

    cd "$ORGPATH"
}

installCMake()
{
    CMAKEVER=$1
    if [ -z $CMAKEVER ]; then
        CMAKEVER=3.19.7
    fi

    ORGDIR=$PWD
    OUTDIR=$(mktemp -d)
    if [ -z "$OUTDIR" ] || [ ! -d "$OUTDIR" ]; then
        exitWithError "Failed to create temporary directory"
    fi

    cd "$OUTDIR"
    exitOnError "Failed to switch to temp directory : $OUTDIR"

    showInfo "Installing CMake version : $CMAKEVER"

    wget "https://github.com/Kitware/CMake/releases/download/v${CMAKEVER}/cmake-${CMAKEVER}.tar.gz"
    wget "https://github.com/Kitware/CMake/releases/download/v${CMAKEVER}/cmake-${CMAKEVER}-SHA-256.txt"
    grep "cmake-${CMAKEVER}.tar.gz" "cmake-${CMAKEVER}-SHA-256.txt" | sha256sum --check -
    exitOnError "SHA256 verification failed for cmake-${CMAKEVER}.tar.gz"
    tar xvzf ./cmake-${CMAKEVER}.tar.gz
    cd cmake-${CMAKEVER}

    showInfo "Bootstrapping CMake..."
    ./bootstrap

    showInfo "Building CMake..."
    make
    exitOnError "Error building CMake ${CMAKEVER}"

    showInfo "Installing CMake..."
    sudo make install
    exitOnError "Error installing CMake ${CMAKEVER}"

    cd "$ORGDIR"
    rm -Rf "$OUTDIR"

}
