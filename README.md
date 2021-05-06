# rbashutils
Collection of bash functions


Quick and dirty way to get it into a shell script

    SCRIPTFILE=$(realpath ${BASH_SOURCE[0]})
    SCRIPTPATH=$(dirname $SCRIPTFILE)
    if [ -z "$IS_RBASHUTILS" ]; then
        # if [[ ! -f "${SCRIPTPATH}/rbashutils.sh" ]]; then
        #     wget https://raw.github.com/wheresjames/rbashutils/main/rbashutils.sh -O "${SCRIPTPATH}/rbashutils.sh"
        # fi
        . "${SCRIPTPATH}/rbashutils.sh"
    fi
