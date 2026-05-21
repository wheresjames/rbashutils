#!/bin/bash

USAGE="Usage: ${BASH_SOURCE[0]} [test #]"

SCRIPTFILE=$(realpath ${BASH_SOURCE[0]})
SCRIPTPATH=$(dirname $SCRIPTFILE)
. "${SCRIPTPATH}/rbashutils.sh"

expandTestCommands()
{
    local INPUT="$1"
    local OUTPUT=
    local PART
    INPUT="${INPUT//,/-}"
    IFS='-' read -r -a RBTEST_PARTS <<< "$INPUT"
    for PART in "${RBTEST_PARTS[@]}"; do
        if [[ "$PART" == *..* ]]; then
            local START="${PART%%..*}"
            local END="${PART##*..}"
            if [[ "$START" =~ ^[0-9]+$ ]] && [[ "$END" =~ ^[0-9]+$ ]] && [[ $START -le $END ]]; then
                local N
                for ((N=START; N<=END; ++N)); do
                    OUTPUT="${OUTPUT:+$OUTPUT-}$N"
                done
            else
                OUTPUT="${OUTPUT:+$OUTPUT-}$PART"
            fi
        else
            OUTPUT="${OUTPUT:+$OUTPUT-}$PART"
        fi
    done
    echo "$OUTPUT"
}

COMMANDS="$(expandTestCommands "$1")"
setCmd "$COMMANDS"

RBTEST_SECTIONS=0

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
    RBTEST_SECTIONS=$((RBTEST_SECTIONS + 1))
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

    showBanner "showBanner(): This is a banner"
    showNotice "showNotice(): This is notice"
    showInfo "showInfo(): This is info"
    showWarning "showWarning(): This is a warning"
    showFail "showFail(): This is a failure"
    showError "showError(): This is an error"
fi


#----------------------------------------------------------
if doTest "3";  then

    R=$(toUpper "HeLlO")
    assertEq "$R" "HELLO"

    R=$(toLower "HeLlO")
    assertEq "$R" "hello"

    R="$(padStr Padded 27 \.)"
    assertEq "$R" "Padded....................."
    echo "padStr     : $R"

    R="$(padStrLeft Padded 27 \.)"
    assertEq "$R" ".....................Padded"
    echo "padStrLeft : $R"

    R="$(limitStr 'This string has been limited' 27)"
    assertEq "$R" "This string has been lim..."
    echo "limitStr   : $R"

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
        printf "\riterFiles(): %-6s %s" "$2" "$(limitStr "$1" 80)"
        sleep .001
    }
    iterateFiles "iterFiles" "/tmp"
    printf "\n"
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

if doTest "14";  then

    TEMP=$(mktemp -d)
    if [ ! -d "$TEMP" ]; then
        exitWithError "Failed to make temp directory : $TEMP"
    fi

    TFILE="$TEMP/hello.txt"
    TFILE2="$TEMP/hello2.txt"
    echo "Hello World!" > "$TFILE"

    # Replace in new file
    replaceAllInFile "Hello" "Goodbye" "$TFILE" "$TFILE2"
    CONTENTS=$(cat "$TFILE")
    if [ "$CONTENTS" != "Hello World!" ]; then
        exitWithError "Replace wrong file contents : $CONTENTS"
    fi
    CONTENTS=$(cat "$TFILE2")
    if [ "$CONTENTS" != "Goodbye World!" ]; then
        exitWithError "Failed to replace file contents : $CONTENTS"
    fi

    # Replace in current file
    replaceAllInFile "Hello" "Goodbye" "$TFILE"
    CONTENTS=$(cat "$TFILE")
    if [ "$CONTENTS" != "Goodbye World!" ]; then
        exitWithError "Failed to replace file contents : $CONTENTS"
    fi

    echo "/Hello\\ World!" > "$TFILE"

    # Replace in current file
    replaceAllInFile "/Hello\\" "\\Goodbye/" "$TFILE"
    CONTENTS=$(cat "$TFILE")
    if [ "$CONTENTS" != "\\Goodbye/ World!" ]; then
        exitWithError "Failed to replace file contents : $CONTENTS"
    fi

    # Cleanup
    unlink "$TFILE"
    unlink "$TFILE2"
    rmdir "$TEMP"

fi


#----------------------------------------------------------
# trimWs, containsSpaces
if doTest "15";  then

    R=$(trimWs "  hello  ")
    assertEq "$R" "hello" "trimWs: leading/trailing spaces"

    R=$(trimWs "	tabbed	")
    assertEq "$R" "tabbed" "trimWs: leading/trailing tabs"

    R=$(trimWs "already")
    assertEq "$R" "already" "trimWs: no whitespace to trim"

    R=$(trimWs "   ")
    assertEq "$R" "" "trimWs: all spaces"

    if containsSpaces "has space"; then
        showInfo "containsSpaces: correctly detected space"
    else
        exitWithError "containsSpaces: failed to detect space in 'has space'"
    fi

    if ! containsSpaces "nospace"; then
        showInfo "containsSpaces: correctly reported no space"
    else
        exitWithError "containsSpaces: false positive on 'nospace'"
    fi

fi


#----------------------------------------------------------
# filterLines
if doTest "16";  then

    ML="apple pie
banana split
cherry bomb
apple cider"

    R=$(filterLines "$ML" "^apple" 10)
    if ! findInStr "$R" "apple pie"; then
        exitWithError "filterLines: missing 'apple pie'"
    fi
    if ! findInStr "$R" "apple cider"; then
        exitWithError "filterLines: missing 'apple cider'"
    fi
    if findInStr "$R" "banana"; then
        exitWithError "filterLines: 'banana' should not be in results"
    fi

    # MAX=1 should stop after first match
    R=$(filterLines "$ML" "apple" 1)
    if findInStr "$R" "apple cider"; then
        exitWithError "filterLines: MAX=1 returned more than one match"
    fi

    # No-match returns empty
    R=$(filterLines "$ML" "mango" 10)
    assertEq "$(trimWs "$R")" "" "filterLines: no-match should be empty"

fi


#----------------------------------------------------------
# strPos, strrPos, startsWith, endsWith
if doTest "17";  then

    R=$(strPos "hello world" "world")
    assertEq "$R" "6" "strPos: 'world' in 'hello world'"

    R=$(strPos "hello world" "hello")
    assertEq "$R" "0" "strPos: 'hello' at position 0"

    R=$(strPos "hello world" "xyz")
    assertEq "$R" "-1" "strPos: not found should be -1"

    R=$(strrPos "abcabc" "bc")
    assertEq "$R" "4" "strrPos: last 'bc' in 'abcabc'"

    R=$(strrPos "hello" "xyz")
    assertEq "$R" "-1" "strrPos: not found should be -1"

    if startsWith "hello world" "hello"; then
        showInfo "startsWith: valid prefix detected"
    else
        exitWithError "startsWith: failed to detect valid prefix"
    fi

    if ! startsWith "hello world" "world"; then
        showInfo "startsWith: non-prefix correctly rejected"
    else
        exitWithError "startsWith: false positive on non-prefix"
    fi

    if endsWith "hello world" "world"; then
        showInfo "endsWith: valid suffix detected"
    else
        exitWithError "endsWith: failed to detect valid suffix"
    fi

    if ! endsWith "hello world" "hello"; then
        showInfo "endsWith: non-suffix correctly rejected"
    else
        exitWithError "endsWith: false positive on non-suffix"
    fi

fi


#----------------------------------------------------------
# setCmd, getCmds, isCmd, delCmd
if doTest "18";  then

    setCmd "build-test-deploy"

    if ! isCmd "build";  then exitWithError "isCmd: 'build' not found in dash-list";  fi
    if ! isCmd "test";   then exitWithError "isCmd: 'test' not found in dash-list";   fi
    if ! isCmd "deploy"; then exitWithError "isCmd: 'deploy' not found in dash-list"; fi
    if isCmd "clean";    then exitWithError "isCmd: 'clean' should not be in dash-list"; fi

    setCmd "alpha,beta,gamma"

    if ! isCmd "alpha"; then exitWithError "isCmd: 'alpha' not found in comma-list"; fi
    if ! isCmd "beta";  then exitWithError "isCmd: 'beta' not found in comma-list";  fi
    if ! isCmd "gamma"; then exitWithError "isCmd: 'gamma' not found in comma-list"; fi
    if isCmd "delta";   then exitWithError "isCmd: 'delta' should not be in comma-list"; fi

    delCmd "beta"
    if isCmd "beta";    then exitWithError "delCmd: 'beta' should have been removed"; fi
    if ! isCmd "alpha"; then exitWithError "delCmd: 'alpha' should still be present"; fi
    if ! isCmd "gamma"; then exitWithError "delCmd: 'gamma' should still be present"; fi

    # Restore original command list
    setCmd "$COMMANDS"

fi


#----------------------------------------------------------
# showOnError, showOnSuccess, showStatus, doIfFail, warnOnError
if doTest "19";  then

    true
    showOnSuccess "showOnSuccess: true succeeded (expected)"

    false
    showOnError "showOnError: false failed (expected)"

    true
    showStatus "showStatus: success path (expected)" "showStatus: error path (should NOT appear)"

    false
    showStatus "showStatus: success path (should NOT appear)" "showStatus: error path (expected)"

    # doIfFail: fallback command should fire after false
    DOFAIL_TRIGGERED=
    false
    doIfFail "" "eval DOFAIL_TRIGGERED=YES"
    assertEq "$DOFAIL_TRIGGERED" "YES" "doIfFail: fallback not triggered on failure"

    # doIfFail: fallback must NOT fire after true
    DOFAIL_TRIGGERED=
    true
    doIfFail "" "eval DOFAIL_TRIGGERED=YES"
    assertEq "$DOFAIL_TRIGGERED" "" "doIfFail: fallback should not trigger on success"

    # warnOnError: returns non-zero after a failed command
    false
    warnOnError "warnOnError: this warning is expected"
    if [ $? -eq 0 ]; then
        exitWithError "warnOnError: should have returned non-zero after failure"
    fi

    # warnOnError: passes through after a successful command
    true
    warnOnError "warnOnError: should not print this"
    assertEq "$?" "0" "warnOnError: should return 0 after success"

fi


#----------------------------------------------------------
# addLinesToFile, delLinesFromFile
if doTest "20";  then

    TEMP=$(mktemp -d)
    TFILE="$TEMP/lines.txt"
    printf "line one\nline two\nline three\n" > "$TFILE"

    # Add a new line
    addLinesToFile "$TFILE" "line four"
    if ! grep -qF "line four" "$TFILE"; then
        exitWithError "addLinesToFile: 'line four' was not added"
    fi

    # Adding an existing line must not duplicate it
    addLinesToFile "$TFILE" "line one"
    COUNT=$(grep -cF "line one" "$TFILE")
    assertEq "$COUNT" "1" "addLinesToFile: duplicate line written"

    # Delete a line
    delLinesFromFile "$TFILE" "line two"
    if grep -qF "line two" "$TFILE"; then
        exitWithError "delLinesFromFile: 'line two' was not removed"
    fi

    # Other lines must still be present
    if ! grep -qF "line one" "$TFILE"; then
        exitWithError "delLinesFromFile: 'line one' was incorrectly removed"
    fi
    if ! grep -qF "line three" "$TFILE"; then
        exitWithError "delLinesFromFile: 'line three' was incorrectly removed"
    fi

    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
# findParentWithFile
if doTest "21";  then

    TEMP=$(mktemp -d)
    mkdir -p "$TEMP/a/b/c"
    touch "$TEMP/a/marker.txt"

    # Find from deep child
    R=$(findParentWithFile "$TEMP/a/b/c" "marker.txt")
    assertEq "$R" "$TEMP/a" "findParentWithFile: wrong parent path from deep child"

    # File is in the start directory itself
    R=$(findParentWithFile "$TEMP/a" "marker.txt")
    assertEq "$R" "$TEMP/a" "findParentWithFile: file in start dir"

    # File does not exist anywhere
    R=$(findParentWithFile "$TEMP/a/b/c" "nonexistent.txt")
    assertEq "$R" "" "findParentWithFile: should return empty when not found"

    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
# rmtree, remkdir
if doTest "22";  then

    TEMP=$(mktemp -d)
    mkdir -p "$TEMP/subtree/deep"
    touch "$TEMP/subtree/file.txt"

    rmtree "$TEMP/subtree"
    if [ -d "$TEMP/subtree" ]; then
        exitWithError "rmtree: directory was not removed"
    fi

    # rmtree on non-existent path must be silent (no error)
    rmtree "$TEMP/subtree"
    showInfo "rmtree: non-existent path handled silently"

    # rmtree: safety guard — path too short must refuse
    rmtree "/a"
    showInfo "rmtree: short path guard did not crash"

    # remkdir: creates directory
    remkdir "$TEMP/fresh"
    if [ ! -d "$TEMP/fresh" ]; then
        exitWithError "remkdir: directory was not created"
    fi

    # remkdir: clears existing directory contents
    touch "$TEMP/fresh/existing.txt"
    remkdir "$TEMP/fresh"
    if [ ! -d "$TEMP/fresh" ]; then
        exitWithError "remkdir: directory missing after remkdir on existing dir"
    fi
    if [ -f "$TEMP/fresh/existing.txt" ]; then
        exitWithError "remkdir: directory was not cleared"
    fi

    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
# getPassword — length, persistence, permissions, regeneration, custom charset
if doTest "23";  then

    TEMP=$(mktemp -d)

    # Generate and save
    PWD1=$(getPassword 16 "testpwd" "$TEMP")
    assertEq "${#PWD1}" "16" "getPassword: wrong length"

    PWDFILE="$TEMP/testpwd.pwd"
    if [ ! -f "$PWDFILE" ]; then
        exitWithError "getPassword: password file not created at $PWDFILE"
    fi

    PERMS=$(stat -c "%a" "$PWDFILE")
    assertEq "$PERMS" "600" "getPassword: file permissions should be 600"

    # Second call must reload same password
    PWD2=$(getPassword 16 "testpwd" "$TEMP")
    assertEq "$PWD1" "$PWD2" "getPassword: password not reloaded from file"

    # NEW flag forces regeneration
    PWD3=$(getPassword 16 "testpwd" "$TEMP" "A-Za-z0-9" "NEW")
    assertEq "${#PWD3}" "16" "getPassword: NEW password wrong length"

    # Unsaved (no name): just a random string of the right length
    PWD4=$(getPassword 24)
    assertEq "${#PWD4}" "24" "getPassword: unsaved password wrong length"

    # Custom charset
    PWD5=$(getPassword 32 "" "" "0-9")
    if [[ ! "$PWD5" =~ ^[0-9]+$ ]]; then
        exitWithError "getPassword: custom charset not respected: $PWD5"
    fi

    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
# setEnv — env var set, written to file, updated without duplication
if doTest "24";  then

    TEMP=$(mktemp -d)
    ENVFILE="$TEMP/test.env"
    touch "$ENVFILE"

    setEnv "RBTEST_SETENV_VAR" "hello123" "$ENVFILE"
    assertEq "$RBTEST_SETENV_VAR" "hello123" "setEnv: variable not set in env"
    if ! grep -q "export RBTEST_SETENV_VAR=hello123" "$ENVFILE"; then
        exitWithError "setEnv: variable not written to file"
    fi

    # Update — must not write a second entry
    setEnv "RBTEST_SETENV_VAR" "updated456" "$ENVFILE"
    assertEq "$RBTEST_SETENV_VAR" "updated456" "setEnv: variable not updated in env"
    if ! grep -q "export RBTEST_SETENV_VAR=updated456" "$ENVFILE"; then
        exitWithError "setEnv: updated value not in file"
    fi
    COUNT=$(grep -c "export RBTEST_SETENV_VAR" "$ENVFILE")
    assertEq "$COUNT" "1" "setEnv: duplicate entries written to file"

    # Invalid variable name must be rejected
    OUTPUT=$(bash -c ". \"$SCRIPTPATH/rbashutils.sh\"; setEnv '123bad' 'val'" 2>&1)
    if [ $? -eq 0 ]; then
        exitWithError "setEnv: invalid variable name should have failed"
    fi

    unset RBTEST_SETENV_VAR
    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
# countFiles with/without CNTDIRS, lastModified numeric result
if doTest "25";  then

    TEMP=$(mktemp -d)
    mkdir -p "$TEMP/sub1" "$TEMP/sub2"
    touch "$TEMP/file1.txt" "$TEMP/file2.txt" "$TEMP/sub1/file3.txt"

    # Files only (no dirs)
    R=$(countFiles "$TEMP")
    assertEq "$R" "3" "countFiles: expected 3 files (dirs excluded)"

    # Files + directories
    R=$(countFiles "$TEMP" YES)
    assertEq "$R" "5" "countFiles: expected 5 (3 files + 2 dirs)"

    # Empty directory
    R=$(countFiles "$TEMP/sub2")
    assertEq "$R" "0" "countFiles: empty dir should count 0"

    # Non-existent path
    R=$(countFiles "/nonexistent/rbtest_path_xyz")
    assertEq "$R" "0" "countFiles: non-existent path should return 0"

    # lastModified returns a positive integer
    TS=$(lastModified "$TEMP")
    if [[ ! "$TS" =~ ^[0-9]+$ ]]; then
        exitWithError "lastModified: non-numeric result: '$TS'"
    fi
    if [ "$TS" -le 0 ]; then
        exitWithError "lastModified: timestamp should be > 0, got $TS"
    fi

    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
# compareVersion — direct return values and operator matching
if doTest "26";  then

    R=$(compareVersion "1.2.3" "1.2.4")
    assertEq "$R" "<" "compareVersion: 1.2.3 < 1.2.4"

    R=$(compareVersion "1.2.4" "1.2.3")
    assertEq "$R" ">" "compareVersion: 1.2.4 > 1.2.3"

    R=$(compareVersion "1.2.3" "1.2.3")
    assertEq "$R" "=" "compareVersion: equal versions"

    R=$(compareVersion "2.0" "1.9.9")
    assertEq "$R" ">" "compareVersion: major bump"

    R=$(compareVersion "1.0" "1.0.0")
    assertEq "$R" "=" "compareVersion: trailing zero equivalent"

    R=$(compareVersion "10.0" "9.9")
    assertEq "$R" ">" "compareVersion: 10 > 9 (must be numeric, not lexicographic)"

    if ! compareVersion "1.2.3" "1.2.3" "=";  then exitWithError "compareVersion op =:  equal should match";       fi
    if ! compareVersion "1.2.4" "1.2.3" ">="; then exitWithError "compareVersion op >=: greater should match";     fi
    if ! compareVersion "1.2.3" "1.2.3" ">="; then exitWithError "compareVersion op >=: equal should match";       fi
    if ! compareVersion "1.2.2" "1.2.3" "<="; then exitWithError "compareVersion op <=: less should match";        fi
    if ! compareVersion "1.2.3" "1.2.3" "<="; then exitWithError "compareVersion op <=: equal should match";       fi
    if ! compareVersion "1.2.3" "1.2.4" "><"; then exitWithError "compareVersion op ><: not-equal should match";   fi
    if   compareVersion "1.2.3" "1.2.3" "><"; then exitWithError "compareVersion op ><: equal should NOT match";   fi

fi


#----------------------------------------------------------
# isCommand
if doTest "27";  then

    if ! isCommand "bash"; then
        exitWithError "isCommand: 'bash' should be found"
    fi

    if ! isCommand "ls"; then
        exitWithError "isCommand: 'ls' should be found"
    fi

    if isCommand "definitely_not_a_real_command_rbtest_xyz"; then
        exitWithError "isCommand: non-existent command should not be found"
    fi

fi


#----------------------------------------------------------
# getSecretsPath — path creation and return value
if doTest "28";  then

    TEMP=$(mktemp -d)

    # Explicit path returned as-is and created
    R=$(getSecretsPath "passwords" "$TEMP/secrets")
    assertEq "$R" "$TEMP/secrets" "getSecretsPath: explicit path not returned"
    if [ ! -d "$TEMP/secrets" ]; then
        exitWithError "getSecretsPath: path not created"
    fi

    # Sub-path is created on demand
    R=$(getSecretsPath "tokens" "$TEMP/tokens")
    assertEq "$R" "$TEMP/tokens" "getSecretsPath: sub-path not returned"
    if [ ! -d "$TEMP/tokens" ]; then
        exitWithError "getSecretsPath: sub-path not created"
    fi

    # RBASHUTILS_SECRETS fallback
    OLD_SECRETS=$RBASHUTILS_SECRETS
    RBASHUTILS_SECRETS="$TEMP/via_secret_var"
    R=$(getSecretsPath "certs")
    assertEq "$R" "$TEMP/via_secret_var/certs" "getSecretsPath: RBASHUTILS_SECRETS fallback"
    if [ ! -d "$TEMP/via_secret_var/certs" ]; then
        exitWithError "getSecretsPath: RBASHUTILS_SECRETS path not created"
    fi
    RBASHUTILS_SECRETS=$OLD_SECRETS

    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
# waitWhile — immediate return and retry limit
if doTest "29";  then

    # Condition already false: must return 0 immediately
    waitWhile "echo 'no match here'" "xyz_rbtest" "should not print dots" 1 1
    assertEq "$?" "0" "waitWhile: should return 0 when condition is already false"

    # Condition stays true: must time out and return non-zero
    waitWhile "echo 'hello world'" "hello" "timing out (expected)..." 2 1
    if [ $? -eq 0 ]; then
        exitWithError "waitWhile: should have timed out with retry limit"
    fi
    showInfo "waitWhile: timed out correctly"

fi


#----------------------------------------------------------
# limitStr edge cases
if doTest "30";  then

    # Shorter than limit: no change
    R=$(limitStr "short" 20)
    assertEq "$R" "short" "limitStr: short string should not be truncated"

    # String length equals effective limit (LN - len(ending) = 20-3 = 17): no truncation
    R=$(limitStr "seventeen_chars!!" 20)
    assertEq "$R" "seventeen_chars!!" "limitStr: string at effective limit should not be truncated"

    # Exceeds limit with default ending
    R=$(limitStr "This is a long string" 13)
    assertEq "$R" "This is a ..." "limitStr: truncated with default '...'"

    # Custom ending
    R=$(limitStr "Hello World" 8 "~")
    assertEq "$R" "Hello W~" "limitStr: truncated with custom ending"

    # Empty string
    R=$(limitStr "" 10)
    assertEq "$R" "" "limitStr: empty string"

fi

if doTest "31";  then

    TEMP=$(mktemp -d)

    # Logging
    LOGFILE="$TEMP/rbashutils.log"
    setLogFile "$LOGFILE"
    setLogLevel debug
    showDebug "debug message"
    if ! grep -qF "[DEBUG] debug message" "$LOGFILE"; then
        exitWithError "setLogFile/showDebug: debug message not written"
    fi
    setLogLevel notice
    setLogFile ""

    # Command runners
    runCmdCapture RBTEST_CAPTURE printf "hello %s" "world"
    assertEq "$RBTEST_CAPTURE" "hello world" "runCmdCapture: wrong output"
    if ! runCmdRetry --retries 2 --delay 0 true; then
        exitWithError "runCmdRetry: true should succeed"
    fi
    if runCmdQuiet false; then
        exitWithError "runCmdQuiet: false should fail"
    fi

    # Direct argument parser
    parseArgs RBARGS_ --output=dist -xz first --name "hello world" second
    assertEq "$RBARGS_output" "dist" "parseArgs: --output"
    assertEq "$RBARGS_x" "ON" "parseArgs: -x"
    assertEq "$RBARGS_z" "ON" "parseArgs: -z"
    assertEq "$RBARGS_name" "hello world" "parseArgs: --name value"
    assertEq "$RBARGS_1" "first" "parseArgs: positional 1"
    assertEq "$RBARGS_2" "second" "parseArgs: positional 2"
    assertEq "$RBARGS_COUNT" "2" "parseArgs: positional count"

    # Validators
    isValidVarName "_ok123" || exitWithError "isValidVarName: valid name rejected"
    ! isValidVarName "123bad" || exitWithError "isValidVarName: invalid name accepted"
    isValidDomain "example.com" || exitWithError "isValidDomain: valid domain rejected"
    ! isValidDomain "bad..example" || exitWithError "isValidDomain: invalid domain accepted"
    isValidPort "443" || exitWithError "isValidPort: valid port rejected"
    ! isValidPort "70000" || exitWithError "isValidPort: invalid port accepted"
    isSafePath "$TEMP/safe" || exitWithError "isSafePath: safe path rejected"

    # Temp cleanup
    makeTempDir RBTEST_TMPDIR
    if [ ! -d "$RBTEST_TMPDIR" ]; then
        exitWithError "makeTempDir: directory not created"
    fi
    cleanupNow
    if [ -e "$RBTEST_TMPDIR" ]; then
        exitWithError "cleanupNow: temp directory not removed"
    fi

    # Atomic file helpers
    AFILE="$TEMP/atomic.txt"
    writeFileAtomic "$AFILE" "alpha"
    appendLineOnce "$AFILE" "beta"
    appendLineOnce "$AFILE" "beta"
    replaceLineAtomic "$AFILE" "alpha" "gamma"
    COUNT=$(grep -cF "beta" "$AFILE")
    assertEq "$COUNT" "1" "appendLineOnce: duplicate line written"
    if ! grep -qF "gamma" "$AFILE"; then
        exitWithError "replaceLineAtomic: replacement missing"
    fi

    # Lock helper
    if ! withLock "$TEMP/test.lock" true; then
        exitWithError "withLock: command should succeed"
    fi

    # Strict mode is checked in a subshell so it cannot affect the test runner.
    bash -c ". \"$SCRIPTPATH/rbashutils.sh\"; rbashutilsStrictMode; test \"\${RBASHUTILS_LOADED}\" = YES"
    exitOnError "rbashutilsStrictMode: subshell check failed"

    rm -Rf "$TEMP"

fi


#----------------------------------------------------------
echo
showInfo "Completed $RBTEST_SECTIONS test section(s)"

doExit 0
