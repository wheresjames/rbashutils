#!/bin/bash

USAGE="Usage: ${BASH_SOURCE[0]} <command>"

ROOTDIR="${BASH_SOURCE%/*}"
if [[ ! -d "$ROOTDIR" ]]; then ROOTDIR="$PWD"; fi
. "${ROOTDIR}/rbashutils.sh"


#----------------------------------------------------------
echo
showVars '-' BASH_SOURCE ROOTDIR

#----------------------------------------------------------
echo
boxStr '*' "This string is in a box"

#----------------------------------------------------------
echo
showInfo "showInfo(): This is info"
showWarning "showWarning(): This is a warning"
showFail "showFail(): This is a failure"
showError "showError(): This is an error"


#----------------------------------------------------------
setCmd "build-package-upload"
if ! isCmd "build"; then
    exitWithError "'build' command not found"
fi
if ! isCmd "package"; then
    exitWithError "'package' command not found"
fi
if ! isCmd "upload"; then
    exitWithError "'upload' command not found"
fi
if isCmd "what"; then
    exitWithError "'what' command found"
fi
delCmd "build"
if isCmd "build"; then
    exitWithError "'build' command found"
fi


#----------------------------------------------------------
if ! findInStr "what a world" "world"; then
    exitWithError "world not found"
fi

if findIn "cat /etc/hosts" "127.0.0.1"; then
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


#----------------------------------------------------------
MYPASSWORD=$(getPassword 32)
showInfo "Create password (A-Za-z0-9) : $MYPASSWORD"

MYOTHERPASSWORD=$(getPassword 64 "" "" "A-Za-z0-9!@#$%&*")
showInfo "Create another password (A-Za-z0-9!@#$%&*) : $MYOTHERPASSWORD"


#----------------------------------------------------------
if isOnline "https://www.google.com"; then
    showInfo "Google seems to be working today"
else
    showFail "Google seems to be broken today"
fi

FF=$(findFile "/usr/bin" "bitm.*")
showInfo "Found file : $FF"

# WIFI=$(getWifi)
# showInfo "WIFI: $WIFI"

#----------------------------------------------------------

LASTMOD=$(lastModified "/tmp")
showInfo "/tmp last modified : $LASTMOD"

#----------------------------------------------------------
# Version comparison
assertVersion "1.2.3" "1.2.4" "<"
assertVersion "1.2.4" "1.2.3" ">"
assertVersion "1.2.3" "1.2.3" "="
assertVersion "1.2.3" "1.2.3" "<="
assertVersion "1.2.3" "1.2.3" "<="
assertVersion "1.2.4" "1.2.3" ">="
assertVersion "1.2.1" "1.2.3" "<="
assertVersion "1.2.2" "1.2.3" "><"
assertVersion "1.2.4" "1.2.3" "><"
assertVersion "1.2" "1.2.3" "<"
assertVersion "" "1.2.3" "<"
assertVersion "" "" "="

#----------------------------------------------------------
# shuf -i 1-100000 -n 1

echo

# CURTIME=`date`
# showInfo "Current date string : $CURTIME"
# waitUntil "date" "56" "Waiting for a 56 to appear in the current date string..." 10 1
# showStatus "Saw a 56 in the date string" \
#            "Didn't see a 56 in the date string after 10 seconds of waiting"

waitUntil "shuf -i 1-100000 -n 1" "56" "Waiting for a 56 to appear in a random string of numbers..." 10 1
showStatus "Saw a 56 in the random string of numbers" \
           "Didn't see a 56 in the random string of numbers after 10 seconds of waiting"
