# rbashutils
Collection of bash functions


Quick and dirty way to get it into a shell script


    if [ -z "$IS_RBASHUTILS" ]; then
        SCRIPTPATH=$(realpath ${BASH_SOURCE[0]})
        ROOTDIR=$(dirname $SCRIPTPATH)
        if [ ! -f "${ROOTDIR}/rbashutils.sh" ]; then
            wget https://raw.github.com/wheresjames/rbashutils/v0.1.1/rbashutils.sh -O "${ROOTDIR}/rbashutils.sh"
        fi
        . "${ROOTDIR}/rbashutils.sh"
    fi
