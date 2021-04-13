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

    local ORGPATH=`pwd`

    if [ ! -d "${PRJSUB}" ]; then
        mkdir -p "${PRJSUB}"
    fi

    cd "${PRJSUB}"

    # Need checkout?
    if [ ! -d "${PRJSUB}/${PRJNAME}" ]; then
        showInfo "Checking out: ${PRJNAME}"
        git clone ${PRJURL} ${PRJNAME}
    fi

    # Update
    cd "${PRJSUB}/${PRJNAME}"

    # Checkout branch
    if [ ! -z $PRJBRANCH ]; then
        showInfo "Switching to branch: ${PRJBRANCH}"
        git checkout ${PRJBRANCH}
        git pull
    fi

    # Tag repo
    if [ ! -z "$PRJGITTAG" ]; then
        showInfo "Tagging: ${PRJNAME} -> ${PRJGITTAG}"
        git tag "${PRJGITTAG}"
        warnOnError "Unable to tag git: ${PRJGITTAG}"
        git push origin "${PRJGITTAG}"
    fi

    cd $ORGPATH
}

installCMake()
{
    CMAKEVER=$1
    if [ -z $CMAKEVER ]; then
        CMAKEVER=3.19.7
    fi

    ORGDIR=$PWD
    OUTDIR=`mktemp`

    if [ -z $OUTDIR ]; then
        exitWithError "Failed to create temporary directory name"
    fi

    if [ ! -f $OUTDIR ]; then
        exitWithError "Failed to create temporary directory file"
    fi

    rm "$OUTDIR"
    mkdir -p "$OUTDIR"
    exitOnError "Failed to create temp directory : $OUTDIR"

    cd "$OUTDIR"
    exitOnError "Failed to switch to temp directory : $OUTDIR"

    showInfo "Installing CMake version : $CMAKEVER"

    wget https://github.com/Kitware/CMake/releases/download/v${CMAKEVER}/cmake-${CMAKEVER}.tar.gz
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