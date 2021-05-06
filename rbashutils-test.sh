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
    if isCmd "$1" || [ -z $(getCmds) ]; then return 0; else return -1; fi
}

#----------------------------------------------------------
echo
echo ":: $(createBuildString) ::"


#----------------------------------------------------------
showVars COMMANDS BASH_SOURCE SCRIPTFILE SCRIPTPATH



#----------------------------------------------------------
if doTest "1";  then
    printf "\n--- 1 ---\n"

    showVars \# BASH_SOURCE
    showVars !\* BASH_SOURCE

    boxStr "This string is in a box"
    boxStr '*' "This string is in a box"
    boxStr '*@' "This string is in a box"
fi


#----------------------------------------------------------
if doTest "2";  then
    printf "\n--- 2 ---\n"

    showInfo "showInfo(): This is info"
    showWarning "showWarning(): This is a warning"
    showFail "showFail(): This is a failure"
    showError "showError(): This is an error"
fi


#----------------------------------------------------------
if doTest "3";  then
    printf "\n--- 3 ---\n"

    echo "padStr     : $(padStr Padded 27 \.)"
    echo "padStrLeft : $(padStrLeft Padded 27 \.)"
    echo "limitStr   : $(limitStr 'This string has been limited' 27)"

fi


#----------------------------------------------------------
if doTest "4";  then
    printf "\n--- 4 ---\n"

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
    printf "\n--- 5 ---\n"

    MYPASSWORD=$(getPassword 32)
    showInfo "Create password (A-Za-z0-9) : $MYPASSWORD"

    MYOTHERPASSWORD=$(getPassword 64 "" "" "A-Za-z0-9!@#$%&*")
    showInfo "Create another password (A-Za-z0-9!@#$%&*) : $MYOTHERPASSWORD"
fi


#----------------------------------------------------------
if doTest "6";  then
    printf "\n--- 6 ---\n"

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
    printf "\n--- 7 ---\n"

    LASTMOD=$(lastModified "/tmp")
    showInfo "/tmp last modified : $LASTMOD"
fi


#----------------------------------------------------------
# Version comparison
if doTest "8";  then
    printf "\n--- 8 ---\n"

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
    printf "\n--- 9 ---\n"

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
    printf "\n--- 10 ---\n"

    # CURTIME=`date`
    # showInfo "Current date string : $CURTIME"
    # waitUntil "date" "56" "Waiting for a 56 to appear in the current date string..." 10 1
    # showStatus "Saw a 56 in the date string" \
    #            "Didn't see a 56 in the date string after 10 seconds of waiting"

    waitUntil "shuf -i 1-100000 -n 1" "5" "Waiting for a 5 to appear in a random string of numbers..." 10 1
    showStatus "Saw a 5 in the random string of numbers" \
            "Didn't see a 5 in the random string of numbers after 10 seconds of waiting"
fi


doExit 0