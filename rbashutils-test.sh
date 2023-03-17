#!/bin/bash

USAGE="Usage: ${BASH_SOURCE[0]} [test #]"

SCRIPTFILE=$(realpath ${BASH_SOURCE[0]})
SCRIPTPATH=$(dirname $SCRIPTFILE)
if [ -z "$IS_RBASHUTILS" ]; then
    # if [[ ! -f "${SCRIPTPATH}/rbashutils.sh" ]]; then
    #     wget https://raw.github.com/wheresjames/rbashutils/main/rbashutils.sh -O "${SCRIPTPATH}/rbashutils.sh"
    # fi
    . "${SCRIPTPATH}/rbashutils.sh"
fi

COMMANDS="$1"
setCmd "$COMMANDS"

doCleanup()
{
    printf "\n\n~ exit $@ ~\n\n"
}
onExit doCleanup

doTest()
{
    if ! isCmd "$1" && [ ! -z $(getCmds) ]; then
        return -1
    fi
    printf "\n--- $1 ---\n"
    return 0
}


#----------------------------------------------------------
echo
echo ":: $(createBuildString) ::"


#----------------------------------------------------------
showVars OSTYPE COMMANDS BASH_SOURCE SCRIPTFILE SCRIPTPATH


#----------------------------------------------------------
if doTest "1";  then

    showVars \# BASH_SOURCE
    showVars !\* BASH_SOURCE

    boxStr "This string is in a box"
    boxStr '*' "This string is in a box"
    boxStr '*@' "This string is in a box"
fi


#----------------------------------------------------------
if doTest "2";  then

    showInfo "showInfo(): This is info"
    showWarning "showWarning(): This is a warning"
    showFail "showFail(): This is a failure"
    showError "showError(): This is an error"
fi


#----------------------------------------------------------
if doTest "3";  then

    echo "padStr     : $(padStr Padded 27 \.)"
    echo "padStrLeft : $(padStrLeft Padded 27 \.)"
    echo "limitStr   : $(limitStr 'This string has been limited' 27)"

fi


#----------------------------------------------------------
if doTest "4";  then

    if ! findInStr "what a world" "world"; then
        exitWithError "world not found"
    fi

    if findIn "cat /etc/hosts | grep 12" "127.0.0.1"; then
        showInfo "You have 127.0.0.1 in your hosts file"
    else
        showWarning "You don't have 127.0.0.1 in your hosts file"
    fi

    doIf "cat /etc/hosts" "127.0.0.1" "showInfo You have 127.0.0.1 in your hosts file"

    doIfNot "cat /etc/hosts" "ramalamadingdong" "showInfo You don't have ramalamadingdong in your hosts file"

    date
    doIfSuccess "showInfo date command succeded"

    date
    doIfError "showError date command failed"
fi


#----------------------------------------------------------
if doTest "5";  then

    MYPASSWORD=$(getPassword 32)
    showInfo "Create password (A-Za-z0-9) : $MYPASSWORD"

    MYOTHERPASSWORD=$(getPassword 64 "" "" "A-Za-z0-9!@#$%&*")
    showInfo "Create another password (A-Za-z0-9!@#$%&*) : $MYOTHERPASSWORD"
fi


#----------------------------------------------------------
if doTest "6";  then

    if isOnline "https://www.google.com"; then
        showInfo "Google seems to be working today"
    else
        showFail "Google seems to be broken today"
    fi

    FF=$(findFile "/usr/bin" "bitm.*")
    showInfo "Found file : $FF"

    # WIFI=$(getWifi)
    # showInfo "WIFI: $WIFI"
fi


#----------------------------------------------------------
if doTest "7";  then

    LASTMOD=$(lastModified "/tmp")
    showInfo "/tmp last modified : $LASTMOD"
fi


#----------------------------------------------------------
# Version comparison
if doTest "8";  then

    assertVersion "1.2.3" "1.2.4" "<"
    assertVersion "1.2.4" "1.2.3" ">"
    assertVersion "1.2.3" "1.2.3" "="
    assertVersion "1.2.3" "1.2.3.0" "="
    assertVersion "1.2.3" "1.2.3" "<="
    assertVersion "1.2.3" "1.2.3" "<="
    assertVersion "1.2.4" "1.2.3" ">="
    assertVersion "1.2.1" "1.2.3" "<="
    assertVersion "1.2.2" "1.2.3" "><"
    assertVersion "1.2.4" "1.2.3" "><"
    assertVersion "1.2" "1.2.3" "<"
    assertVersion "" "1.2.3" "<"
    assertVersion "" "" "="
fi


#----------------------------------------------------------
if doTest "9";  then

    showInfo "Files in /tmp : $(countFiles /tmp)"

    iterFiles()
    {
        echo "iterFiles(): $2 $1"
        sleep .001
    }
    iterateFiles "iterFiles" "/tmp"
fi


#----------------------------------------------------------
# shuf -i 1-100000 -n 1
if doTest "10";  then

    DOMAIN="www.google.com"

    if ! isCertValid "$DOMAIN"; then
        showFail "Cert is invalid for $DOMAIN"
    else
        showInfo "Cert is valid for $DOMAIN"
    fi

    echo "start, text: $(getCertTime "$DOMAIN" "start" "text")"
    echo "end, text: $(getCertTime "$DOMAIN" "end" "text")"
    echo "start/end, text: $(getCertTime "$DOMAIN" "start end" "text")"
    echo "start, timestamp: $(getCertTime "$DOMAIN" "start" "timestamp")"
    echo "end, timestamp: $(getCertTime "$DOMAIN" "end" "timestamp")"
    echo "start/end, timestamp: $(getCertTime "$DOMAIN" "start end" "timestamp")"
    echo "Expires in $((($(getCertTime "$DOMAIN" "end" "timestamp") - $(date -u +%s)) / 86400)) days"

fi

#----------------------------------------------------------
# shuf -i 1-100000 -n 1
if doTest "11";  then

    # CURTIME=`date`
    # showInfo "Current date string : $CURTIME"
    # waitUntil "date" "56" "Waiting for a 56 to appear in the current date string..." 10 1
    # showStatus "Saw a 56 in the date string" \
    #            "Didn't see a 56 in the date string after 10 seconds of waiting"

    waitUntil "shuf -i 1-100000 -n 1" "5" "Waiting for a 5 to appear in a random string of numbers..." 10 1
    showStatus "Saw a 5 in the random string of numbers" \
            "Didn't see a 5 in the random string of numbers after 10 seconds of waiting"
fi


if doTest "12";  then

    showInfo "Script arguments: $@"

    CL=$(cmdLineToStr "$@")
    echo "CL: $CL"

    prefixCmdLine PARAMS_ "$CL"
    for p in ${!PARAMS_*}; do
        echo "$p = ${!p}"
    done

    echo

    ARGS=" -at hi --s1=1 --s2=\"a b c\" --s3 \"d e f\" --hello-$%world='why is me' --empty= first -xy= second --escape=\"escape \\\"this\\\"\" -z \"--not-a=switch\""
    echo "ARGS: $ARGS"

    prefixCmdLine ARGS_ "$ARGS"
    for p in ${!ARGS_*}; do
        echo "$p = ${!p}"
    done

    assertEq "$ARGS_a" "ON" "ARGS_a assertion failed"
    assertEq "$ARGS_t" "hi" "ARGS_a assertion failed"
    assertEq "$ARGS_s1" "1" "ARGS_s1 assertion failed"
    assertEq "$ARGS_s2" "a b c" "ARGS_s2 assertion failed"
    assertEq "$ARGS_s3" "d e f" "ARGS_s3 assertion failed"
    assertEq "$ARGS_hello_world" "why is me" "ARGS_hello_world assertion failed"
    assertEq "$ARGS_1" "first" "ARGS_1 assertion failed"
    assertEq "$ARGS_2" "second" "ARGS_2 assertion failed"
    assertEq "$ARGS_escape" "escape \"this\"" "ARGS_escape assertion failed"
    assertEq "$ARGS_x" "ON" "ARGS_x assertion failed"
    assertEq "$ARGS_y" "ON" "ARGS_y assertion failed"
    assertEq "$ARGS_z" "--not-a=switch" "ARGS_z assertion failed"

fi

if doTest "13";  then
    showInfo "OS Type = $(osName)"
    showInfo "Number of Processors = $(numProcs)"
fi

doExit 0
