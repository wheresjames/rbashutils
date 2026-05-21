# rbashutils

A collection of reusable bash utility functions covering string manipulation, display/logging, flow control, file operations, command-line parsing, system setup, and more. Designed to be sourced into any bash script with a single line.

## Table of Contents

- [Quick Start](#quick-start)
- [Running Tests](#running-tests)
- [File Overview](#file-overview)
- [Function Reference](#function-reference)
  - [String Functions](#string-functions)
  - [Display and Logging](#display-and-logging)
  - [Flow Control and Error Handling](#flow-control-and-error-handling)
  - [Command Detection and Waiting](#command-detection-and-waiting)
  - [Command Line Parsing](#command-line-parsing)
  - [File Utilities](#file-utilities)
  - [Environment and Secrets](#environment-and-secrets)
  - [System Utilities](#system-utilities)
  - [Package Management](#package-management)
  - [Git and Build Tools](#git-and-build-tools)
  - [Web and SSL](#web-and-ssl)
- [Project Comparison](#project-comparison)
- [License](#license)

---

## Quick Start

Copy `rbashutils.sh` (and any other modules you need) into your project, then source it near the top of your script:

```bash
SCRIPTFILE=$(realpath "${BASH_SOURCE[0]}")
SCRIPTPATH=$(dirname "$SCRIPTFILE")
. "${SCRIPTPATH}/rbashutils.sh"
```

`rbashutils.sh` has an internal load guard, so it is safe to source more than once. The legacy `IS_RBASHUTILS` variable is still set after sourcing for compatibility with older scripts.

To pull in additional modules:

```bash
. "${SCRIPTPATH}/rbashutils-web.sh"   # web compression, SSL, nginx/apache setup
. "${SCRIPTPATH}/rbashutils-sys.sh"   # hostname / domain configuration
. "${SCRIPTPATH}/rbashutils-code.sh"  # git helpers, cmake installer
```

---

## Running Tests

```bash
# Run all tests
./rbashutils-test.sh

# Run a single test section by number
./rbashutils-test.sh 17

# Run selected sections using the dash-separated command syntax
./rbashutils-test.sh 15-17-30

# Run an inclusive range or comma-separated list
./rbashutils-test.sh 15..30
./rbashutils-test.sh 15,17,30

# Run syntax checks, and shellcheck/shfmt if installed
./rbashutils-run.sh check
```

The dash-separated form is a list of explicit section numbers, not an inclusive range. For example, `15-17-30` runs sections 15, 17, and 30. Use `15..30` for an inclusive range.

---

## File Overview

| File | Description |
|------|-------------|
| `rbashutils.sh` | Core library — strings, logging, flow control, file utils, system info |
| `rbashutils-web.sh` | Web tools — download helpers, minification, SSL/TLS, nginx, apache |
| `rbashutils-sys.sh` | System setup — hostname configuration |
| `rbashutils-code.sh` | Build tools — git helpers, CMake source installer |
| `rbashutils-test.sh` | Test suite (31 sections) |
| `rbashutils-run.sh` | Example entry-point / runner |

---

## Function Reference

### String Functions

#### `padStr <string> <length> [char]`
Right-pads a string to the specified length using `char` (default: space).

```bash
R=$(padStr "Hello" 10 ".")
# R = "Hello....."
```

#### `padStrLeft <string> <length> [char]`
Left-pads a string to the specified length.

```bash
R=$(padStrLeft "42" 6 "0")
# R = "000042"
```

#### `limitStr <string> <length> [ending]`
Truncates a string so the total result (including `ending`, default `...`) fits within `length` characters. Strings already short enough are returned unchanged.

```bash
R=$(limitStr "This is a very long title" 15)
# R = "This is a ve..."

R=$(limitStr "Short" 15)
# R = "Short"
```

#### `trimWs <string>`
Removes leading and trailing whitespace (spaces and tabs).

```bash
R=$(trimWs "   hello world   ")
# R = "hello world"
```

#### `containsSpaces <string>`
Returns 0 (true) if the string contains at least one space character.

```bash
if containsSpaces "$FILENAME"; then
    FILENAME="\"$FILENAME\""
fi
```

#### `toUpper <string>` / `toLower <string>`
Converts a string to all-uppercase or all-lowercase. Works on both Linux and macOS.

```bash
$(toUpper "hello")   # "HELLO"
$(toLower "WORLD")   # "world"
```

#### `strPos <haystack> <needle>`
Returns the character index of the *first* occurrence of `needle` in `haystack`, or `-1` if not found.

```bash
$(strPos "hello world" "world")   # 6
$(strPos "hello world" "xyz")     # -1
```

#### `strrPos <haystack> <needle>`
Returns the character index of the *last* occurrence of `needle`, or `-1` if not found.

```bash
$(strrPos "abcabc" "bc")   # 4
```

#### `startsWith <string> <prefix>`
Returns 0 (true) if `string` begins with `prefix`.

```bash
if startsWith "$FILE" "/tmp/"; then
    echo "This is a temporary file"
fi
```

#### `endsWith <string> <suffix>`
Returns 0 (true) if `string` ends with `suffix`.

```bash
if endsWith "$FILE" ".sh"; then
    echo "This is a shell script"
fi
```

#### `filterLines <text> <regex> <max>`
Returns up to `max` lines from `text` that match the extended regex `regex`.

```bash
OUTPUT=$(some_command)
ERRORS=$(filterLines "$OUTPUT" "^ERROR:" 10)
```

#### `findInStr <string> <pattern>`
Searches `string` for extended-regex `pattern` using `grep -E`. Returns 0 if found. Use this when the pattern is intentionally a regex.

```bash
if findInStr "$LOG_OUTPUT" "Connection refused"; then
    showError "Service is not responding"
fi
```

#### `containsStr <string> <literal>`
Searches `string` for a literal sub-string (no regex — every character is matched exactly). Returns 0 if found. Prefer this over `findInStr` when the search term is plain text that may contain regex metacharacters.

```bash
if containsStr "$FILE_CONTENTS" "api.example.com"; then
    showWarning "Hardcoded hostname found"
fi
```

---

### Display and Logging

All display functions respect whether stdout is a terminal — ANSI colors are only emitted when writing to a TTY.

#### `showDebug` / `showNotice` / `showInfo` / `showWarning` / `showFail` / `showError`
Prints a labeled, color-coded message to stdout.

```bash
showDebug   "Parsed config file"        # cyan   [DEBUG]
showNotice  "Already up to date"        # green  [NOTE]
showInfo    "Starting build..."         # blue   [INFO]
showWarning "Config file not found"     # yellow [WARN]
showFail    "Build step failed"         # red    [FAIL]
showError   "Fatal: missing argument"   # red    [ERROR] with border
```

#### `setLogLevel <level>` / `setLogFile <file>`
Controls message filtering and optional log-file output. Levels are `debug`, `notice`, `info`, `warn`, `error`, and `none`; default is `notice`, which shows all standard messages except debug.

```bash
setLogLevel debug
setLogFile "./deploy.log"
```

#### `showBanner <text>`
Prints a bordered banner — useful for marking major phases in a script.

```bash
showBanner "Deploying to production"
```

#### `boxStr [border-chars] <text>`
Wraps text in an ASCII box. The optional first argument sets the border character(s): one character uses it everywhere; two characters use the first for horizontal borders and the second for vertical sides.

```bash
boxStr "Build complete"
boxStr '*' "Build complete"
boxStr '*@' "Build complete"   # * for horizontal, @ for vertical
```

#### `showVars [border-char] <var> [var ...]`
Displays one or more variable names and their current values in an aligned table. Handy for debugging.

```bash
showVars BUILD_DIR OUTPUT_DIR VERSION
```

---

### Flow Control and Error Handling

#### `exitWithError <message>`
Prints an error banner and exits the script with a non-zero code.

#### `exitOnError <message>`
Exits with an error message if the *previous* command returned non-zero. Place it immediately after any command you want to guard.

```bash
make
exitOnError "Build failed"

rsync -av ./dist/ user@server:/var/www/
exitOnError "Deploy failed"
```

#### `assertNotEmpty <value> <message>`
Exits if `value` is empty or unset.

```bash
assertNotEmpty "$CONFIG_FILE" "CONFIG_FILE must be set before calling this script"
```

#### `assertEq <a> <b> <message>`
Exits if `a` and `b` are not equal (string comparison).

```bash
assertEq "$HTTP_STATUS" "200" "Expected HTTP 200 from health check"
```

#### `showOnError <message>` / `showOnSuccess <message>`
Prints a message only when the previous command failed or succeeded, respectively.

```bash
run_migration
showOnSuccess "Migration applied"
showOnError   "Migration failed — check the logs"
```

#### `showStatus <success-msg> <error-msg>`
Picks one of two messages based on the previous command's exit code.

```bash
run_tests
showStatus "All tests passed" "Some tests failed"
```

#### `doIfError <cmd>` / `doIfSuccess <cmd>`
Executes a command only when the previous command failed or succeeded.

```bash
build_project
doIfSuccess "notify 'Build succeeded'"
doIfError   "notify 'Build failed'"
```

#### `doIfFail <cmd1> <cmd2> [message]`
Runs `cmd1`; if it exits non-zero, optionally prints `message` and runs `cmd2`.

```bash
doIfFail "ping -c1 $HOST" "exitWithError 'Host unreachable'" "Network check failed"
```

#### `doIfFailAndExit <cmd1> <cmd2> [message]`
Like `doIfFail` but also exits after running the fallback.

#### `warnOnError <message>`
Shows a warning if the previous command failed, then returns the failure code so it can be used in `if` conditions.

```bash
git tag "$VERSION"
warnOnError "Tag already exists, skipping"
```

#### `rbashutilsStrictMode`
Enables opt-in strict shell behavior using `set -euo pipefail` and a newline/tab `IFS`. Because strict mode can change existing script behavior, call it explicitly near the top of scripts that are written for it.

```bash
rbashutilsStrictMode
```

#### `runCmd` / `runCmdQuiet` / `runCmdCapture` / `runCmdRetry`
Runs commands using normal shell argument arrays instead of command strings. `runCmd` supports `--dry-run` and `--quiet`; `runCmdCapture <var> <cmd> [args...]` stores stdout in a named variable; `runCmdRetry` retries failed commands.

```bash
runCmd git status --short
runCmd --dry-run rsync -av ./dist/ user@host:/var/www/
runCmdCapture GIT_BRANCH git rev-parse --abbrev-ref HEAD
runCmdRetry --retries 5 --delay 2 curl -fsS "$HEALTH_URL"
```

#### `onExit <function>` / `doExit [code]`
Registers a cleanup function to call on exit, then exits with `code` (default 0).

```bash
cleanup() {
    rm -f /tmp/my_lockfile
    showInfo "Cleanup done"
}
onExit cleanup

# ... rest of script ...

doExit 0
```

#### `makeTempDir` / `makeTempFile` / `cleanupOnExit` / `cleanupPathOnExit` / `cleanupNow`
Creates temporary paths and registers cleanup actions. Pass a variable name to `makeTempDir` or `makeTempFile` to set that variable and automatically remove the generated path when cleanup runs. With no variable name, the path is printed but not auto-registered, because command substitution runs in a subshell. `cleanupOnExit` accepts a simple command (function name or command with arguments). Full shell syntax (pipes, redirections, semicolons) is not supported — wrap complex cleanup logic in a shell function instead.

```bash
makeTempDir WORKDIR
makeTempFile LOCKFILE

# Simple: function name or command + args
cleanupOnExit my_cleanup_fn
cleanupOnExit rm -f /tmp/my.lock

# Complex cleanup: wrap in a function
my_cleanup() {
    rm -f /tmp/my.lock
    echo "done" >> /var/log/app.log
}
cleanupOnExit my_cleanup

cleanupNow
```

---

### Command Detection and Waiting

#### `findIn <command> <pattern>`
Runs `command` (pipe chains supported using `|` in the string) and returns 0 if `pattern` appears in the output.

```bash
if findIn "ps cax" "nginx"; then
    showInfo "nginx is running"
fi

if findIn "cat /etc/hosts | grep 127" "127.0.0.1"; then
    showInfo "Loopback is configured"
fi
```

#### `isCommand <name>`
Returns 0 if `name` resolves to an executable on `$PATH`.

```bash
if ! isCommand "docker"; then
    exitWithError "Docker is required but not installed"
fi
```

#### `requireCommand <cmd> [cmd ...]` / `requireRoot`
Exits with an error if required commands are missing or if the current process is not running as root.

```bash
requireCommand git curl jq
requireRoot
```

#### `doIf <cmd> <pattern> <action> [error-msg]`
Runs `cmd`; if `pattern` is found in the output, runs `action`. Optionally exits with `error-msg` after the action.

```bash
doIf "ufw status" "inactive" "ufw enable"
```

#### `doIfNot <cmd> <pattern> <action> [error-msg]`
Like `doIf` but triggers when the pattern is *not* found.

```bash
doIfNot "ufw show added" "22/tcp" "ufw allow 22/tcp"
doIfNot "ufw show added" "443/tcp" "ufw allow 443/tcp"
```

#### `waitWhile <cmd> <pattern> <prompt> [max-retries] [delay-secs]`
Polls `cmd` repeatedly while `pattern` is present in the output (i.e., waits for the condition to disappear). Returns 0 when gone, non-zero if the retry limit is reached.

```bash
waitWhile "systemctl status myapp" "starting" "Waiting for service to start..." 30 2
exitOnError "Service did not start in time"
```

#### `waitUntil <cmd> <pattern> <prompt> [max-retries] [delay-secs]`
Like `waitWhile` but waits *until* the pattern *appears*.

```bash
waitUntil "cat /var/log/app.log" "Server ready" "Waiting for ready signal..." 60 2
exitOnError "Service never became ready"
```

#### `askYesNo <question>`
Prompts the user interactively and returns 0 for yes, non-zero for no.

```bash
if askYesNo "This will wipe the database. Continue?"; then
    drop_and_recreate_db
fi
```

#### `isValidVarName` / `isValidDomain` / `isValidPort` / `isSafePath`
Validation helpers that return 0 for valid input and non-zero otherwise.

```bash
if ! isValidPort "$PORT"; then
    exitWithError "Invalid port: $PORT"
fi
```

---

### Command Line Parsing

#### `setCmd <list>` / `getCmds` / `isCmd <name>` / `delCmd <name>`
Manages a step list — a dash- or comma-separated string of named commands. Useful for build scripts where you want to run a specific subset of steps.

```bash
# Accept a step list from the first argument
setCmd "$1"   # e.g. "build-test-deploy" or "build,deploy"

if isCmd "build";  then run_build;  fi
if isCmd "test";   then run_tests;  fi
if isCmd "deploy"; then run_deploy; fi

# Conditionally skip a step at runtime
if [ "$SKIP_DEPLOY" = "1" ]; then
    delCmd "deploy"
fi
```

#### `cmdLineToStr "$@"`
Converts the script's argument list into a single escaped string, suitable for passing between scripts or storing in a variable.

```bash
ARGS=$(cmdLineToStr "$@")
```

#### `prefixCmdLine <prefix> <args-string>`
Parses a command-line string and writes each argument into a global variable named `<prefix><key>`. Handles short flags (`-v`), long options (`--output`), key=value pairs, and positional arguments.

```bash
prefixCmdLine PARAMS_ "$(cmdLineToStr "$@")"

echo "Output dir : $PARAMS_output"   # from --output=./dist
echo "Verbose    : $PARAMS_v"        # from -v
echo "First arg  : $PARAMS_1"        # first positional
```

#### `parseArgs <prefix> "$@"`
Parses the current argument array directly into global variables. Long options become `<prefix><name>`, short flags become `<prefix><char>=ON`, positional arguments become `<prefix>1`, `<prefix>2`, and `<prefix>COUNT` stores the positional count.

```bash
parseArgs PARAM_ "$@"
echo "$PARAM_output"
echo "$PARAM_1"
```

---

### File Utilities

#### `findFile <root> <pattern>`
Finds the first file under `root` whose path contains `pattern` (fixed-string match). Returns the full path, or empty if not found.

```bash
CONFIG=$(findFile "/etc" "myapp.conf")
if [ -z "$CONFIG" ]; then exitWithError "Config not found"; fi
```

#### `findParentWithFile <dir> <filename>`
Walks up the directory tree from `dir`, returning the first ancestor directory that contains `filename`. Useful for locating project roots.

```bash
PROJECT_ROOT=$(findParentWithFile "$PWD" "package.json")
assertNotEmpty "$PROJECT_ROOT" "Not inside a Node.js project"
```

#### `addLinesToFile <file> <lines>`
Appends each line in `lines` to `file` only if that line isn't already present.

```bash
addLinesToFile "/etc/environment" "MY_APP_HOME=/opt/myapp"
addLinesToFile "$HOME/.bashrc" "source /opt/myapp/env.sh"
```

#### `delLinesFromFile <file> <lines>`
Removes every line from `file` that exactly matches any line in `lines` (fixed-string, whole-line match). Partial matches are left untouched, so deleting `abc` will not remove a line containing `xabcx`.

```bash
delLinesFromFile "$HOME/.bashrc" "source /opt/myapp/env.sh"
```

#### `replaceAllInFile <find> <replace> <src> [dest]`
Replaces all occurrences of `find` with `replace` in `src`. If `dest` is omitted, edits in place. Uses literal (non-regex) matching via `awk index()`, so any character — including `.`, `*`, `[`, `&`, `/`, `\` — is matched and substituted exactly as written, with no escaping required.

```bash
# Replace a version placeholder in a template, writing to a new file
replaceAllInFile "%%VERSION%%" "$VERSION" "config.template" "config.ini"

# In-place replacement — special characters need no escaping
replaceAllInFile "api.example.com" "$API_HOST" "/etc/myapp/db.conf"
replaceAllInFile "C:\old\path" "C:\new\path" "setup.ini"
```

#### `writeFileAtomic` / `appendLineOnce` / `replaceLineAtomic`
Helpers for safer file updates. `writeFileAtomic` writes through a temporary file and renames it into place, `appendLineOnce` appends only missing whole lines, and `replaceLineAtomic` replaces exact whole-line matches.

```bash
writeFileAtomic "./config.txt" "enabled=true\n"
appendLineOnce "$HOME/.bashrc" "source /opt/myapp/env.sh"
replaceLineAtomic "./config.txt" "enabled=false" "enabled=true"
```

#### `withLock <lockfile> <command> [args...]`
Runs a command only if a lock can be acquired. The current implementation uses a lock directory next to the given lock path and returns non-zero if another process holds it.

```bash
withLock "/tmp/deploy.lock" run_deploy
```

#### `rmtree <dir>`
Recursively deletes `dir` and all its contents. Refuses to act on paths shorter than 3 characters or that resolve to the filesystem root (safety guard).

```bash
rmtree "$BUILD_DIR"
```

#### `remkdir <dir>`
Deletes `dir` if it exists, then creates it fresh. Same safety guards as `rmtree`.

```bash
remkdir "$DIST_DIR"
```

---

### Environment and Secrets

#### `setEnv <name> <value> [file]`
Sets an environment variable in the current shell. If `file` is provided, writes a shell-escaped `export NAME=VALUE` line to that file, replacing any existing export for the same variable without creating duplicates. Values containing spaces or shell metacharacters are preserved safely when the file is sourced later. The variable name must be a valid shell identifier.

```bash
setEnv "DATABASE_URL" "postgres://localhost/mydb" "/etc/myapp.env"
setEnv "APP_GREETING" "hello world" "./app.env"
```

#### `getSecretsPath <name> [path]`
Returns a directory path for storing secrets, creating it if needed. With no `path`, falls back first to `$RBASHUTILS_SECRETS/<name>`, then `./secrets/<name>`.

```bash
SECRETS_DIR=$(getSecretsPath "api-keys")
```

#### `getPassword <length> [name] [path] [charset] [NEW]`
Generates a random password of `length` characters from `charset` (default: `A-Za-z0-9`). If `name` is provided, the password is saved to `<path>/<name>.pwd` (permissions 0600) and reloaded automatically on subsequent calls, so the same password is returned every time. Pass `NEW` as the fifth argument to force regeneration.

```bash
# Generate a one-off password
TEMP_TOKEN=$(getPassword 24)

# Generate and persist a database password
DB_PASS=$(getPassword 32 "db-password" "/etc/myapp/secrets")

# Regenerate if compromised
DB_PASS=$(getPassword 32 "db-password" "/etc/myapp/secrets" "A-Za-z0-9" "NEW")
```

---

### System Utilities

#### `createBuildString`
Returns a build timestamp in `YY.MM.DD.hhmm` format.

```bash
VERSION="1.0.$(createBuildString)"   # e.g. "1.0.25.04.22.1430"
```

#### `osName`
Returns `linux`, `darwin`, or the raw `$OSTYPE` value for other systems.

```bash
if [[ $(osName) == "darwin" ]]; then
    SED="sed -i ''"
else
    SED="sed -i"
fi
```

#### `numProcs`
Returns the number of physical CPU cores. Handles both Linux (`nproc`) and macOS (`sysctl`).

```bash
make -j$(numProcs)
```

#### `countFiles <dir> [count-dirs]`
Recursively counts files under `dir`. Pass any non-empty second argument to also count directories.

```bash
echo "Source files  : $(countFiles ./src)"
echo "Total entries : $(countFiles ./src YES)"
```

#### `iterateFiles <func> <dir>`
Calls `func` once for every file and subdirectory under `dir`, passing the item path and a `[NNN%]` progress string as arguments.

```bash
process_item() {
    local PATH="$1"
    local PROGRESS="$2"
    echo "$PROGRESS Processing: $PATH"
}
iterateFiles process_item "./assets"
```

#### `lastModified <dir>`
Returns the most recent modification timestamp (Unix seconds) of any file in the directory tree. Useful for deciding whether a rebuild is needed.

```bash
if [[ $(lastModified "$SRC_DIR") -gt $(lastModified "$BUILD_DIR") ]]; then
    showInfo "Source changed, rebuilding..."
    run_build
fi
```

#### `compareVersion <v1> <v2> [op]`
Compares two version strings numerically (not lexicographically, so `10.0 > 9.9`). When called without `op`, prints the result symbol (`<`, `=`, or `>`). With `op`, returns 0 if the comparison holds and non-zero otherwise. Valid operators: `=`, `>`, `<`, `>=`, `<=`, `><` (not equal).

```bash
# Print the relationship
compareVersion "1.2.3" "1.2.4"   # prints "<"

# Use as a condition
if ! compareVersion "$(python3 --version)" "3.8" ">="; then
    exitWithError "Python 3.8 or newer is required"
fi
```

#### `assertVersion <v1> <v2> <op>`
Like `compareVersion` with an operator, but exits with an error if the comparison does not hold.

```bash
assertVersion "$(cmake --version)" "3.15" ">="
```

#### `isCertValid <domain> [days]`
Returns 0 if the TLS certificate for `domain` is valid and will not expire within `days` days (default: 1).

```bash
if ! isCertValid "mysite.com" 30; then
    showWarning "Certificate expires within 30 days — renew soon"
fi
```

#### `getCertTime <domain> <which> [format]`
Returns the start and/or end time of a domain's TLS certificate. `which` can be `start`, `end`, or `"start end"` for both. `format` can be `text` (human-readable) or `timestamp` (Unix seconds).

```bash
EXPIRY=$(getCertTime "mysite.com" "end" "timestamp")
DAYS=$(( ($EXPIRY - $(date -u +%s)) / 86400 ))
echo "Certificate expires in $DAYS days"
```

#### `isOnline <url>`
Returns 0 if `url` is reachable (uses `wget --spider`).

```bash
if ! isOnline "https://registry.npmjs.org"; then
    exitWithError "No internet connection — cannot fetch dependencies"
fi
```

---

### Package Management

> These functions are Debian/Ubuntu only and typically require root privileges.

#### `isAptPkgInstalled <package>`
Returns 0 if the package is currently installed.

#### `aptInstall [-q] <package> [package ...]`
Installs one or more packages if not already present. Pass `-q` to suppress "already installed" notices.

```bash
aptInstall git curl build-essential
aptInstall -q jq unzip
```

#### `isAptRepo <repo>` / `addAptRepo <repo>`
Checks whether a repository is already in sources, and adds it if not.

```bash
addAptRepo "ppa:deadsnakes/ppa"
aptInstall python3.11
```

---

### Git and Build Tools

> Defined in `rbashutils-code.sh`.

#### `gitCheckoutOrUpdate <subdir> <name> <url> <branch> [tag]`
Clones `url` into `<subdir>/<name>` if it doesn't exist, then switches to `branch` and pulls. Optionally creates and pushes a git tag.

```bash
gitCheckoutOrUpdate "vendor" "mylib" \
    "https://github.com/org/mylib.git" "main"
```

#### `installCMake [version] [sha256]`
Downloads the CMake source tarball, verifies its SHA-256 checksum, then builds and installs it. Defaults to version `3.19.7`. If `sha256` is supplied, the tarball is verified against that known-good hash (stronger integrity guarantee). Without it, the hash is downloaded from the same server as the tarball and a warning is printed.

```bash
# Default version, hash downloaded from server (with warning)
installCMake

# Specific version with a trusted, hardcoded hash
installCMake 3.27.0 "abc123..."
```

---

### Web and SSL

> Defined in `rbashutils-web.sh`.

#### `downloadTool <name> <url> [dest] [sha256]`
Downloads a file to the local `.tools/` directory. If `sha256` is provided, verifies the checksum before returning the path, including when the tool is already present in the local cache.

```bash
TOOL=$(downloadTool "mybin" "https://example.com/mybin" "" "abc123def456...")
chmod +x "$TOOL"
```

#### `downloadToolCompressed <name> <grep-pattern> <url>`
Downloads a zip archive, locates the file matching `grep-pattern` inside it, and copies it to `.tools/<name>`.

```bash
TOOL=$(downloadToolCompressed "mytool" "mytool-linux-amd64" \
    "https://example.com/mytool-v1.0.zip")
```

#### `initCompress`
Downloads and caches the tools required by `compressWeb` (Closure Compiler, YUI Compressor, html-minifier). Call once before compressing. The bundled Closure Compiler and YUI Compressor downloads are pinned with SHA-256 checksums.

#### `compressWeb <input-dir> <output-dir>`
Minifies an entire web project directory tree: `.js` via Closure Compiler, `.css` via YUI Compressor, `.htm`/`.html` via html-minifier. Other file types are copied as-is. Files already containing `.min.` in their name are copied without reprocessing.

```bash
initCompress
compressWeb "./src/web" "./dist/web"
exitOnError "Web compression failed"
```

#### `parseDomain <domain>`
Splits a domain name into its subdomain and root parts.

```bash
read SUBDOMAIN ROOT <<< $(parseDomain "www.example.com")
# SUBDOMAIN = "www", ROOT = "example.com"
```

#### `createSelfSignedCert <domain> [cert-dir] [subject-info]`
Generates a self-signed RSA-2048 certificate for `domain` valid for 365 days. The certificate is written to `cert-dir` (default: `./certs/<domain>`).

```bash
createSelfSignedCert "localhost" "./certs/localhost"
```

#### `createCertRequest <domain> [cert-dir] [password] [subject-info]`
Generates a private key and CSR for `domain`. The passphrase is passed to `openssl` via a 0600 temporary file so it never appears in the process list. The temporary file is removed after use and on interrupt signals handled by the function.

```bash
createCertRequest "mysite.com" "./certs/mysite"
```

#### `createLetsencryptCert <domain> [retries] [opts]`
Obtains a Let's Encrypt certificate via certbot standalone mode. Temporarily stops apache/nginx if they are running, then restarts them on completion. Set `opts` to `"dummy"` to work around Let's Encrypt rate limits by adding a random subdomain to the request.

```bash
createLetsencryptCert "mysite.com" 3
```

#### `addCertbotRenewCronjob [webroot]`
Adds a daily 2 AM cron job to automatically renew certificates. If `webroot` is provided, certbot uses webroot mode instead of standalone.

```bash
addCertbotRenewCronjob "/var/www/html"
```

#### `installUfw`
Installs UFW, ensures SSH (port 22) is allowed, and enables the firewall.

#### `installNginx <domain> [ssl]`
Installs nginx and writes a server block config for `domain`. Pass `ssl` to also configure HTTPS using an existing Let's Encrypt certificate at `/etc/letsencrypt/live/<domain>/`.

```bash
createLetsencryptCert "mysite.com"
installNginx "mysite.com" ssl
```

#### `installApache <domain> [ssl]`
Installs apache2 and writes a virtual host config for `domain` with SSL redirect.

```bash
createLetsencryptCert "mysite.com"
installApache "mysite.com" ssl
```

---

## Project Comparison

There are many Bash libraries and frameworks with overlapping goals. This section is intended as practical guidance, not a ranking. Project scope, maintenance status, licensing, and supported Bash/POSIX versions should be checked directly before adopting any dependency.

| Project | Primary Focus | Similarities to `rbashutils` | Main Differences | Best Fit |
|---------|---------------|------------------------------|------------------|----------|
| `rbashutils` | Reusable Bash utility functions for scripts, deployment helpers, file operations, environment/secrets, web/server setup, and tests | Small sourceable shell modules; utility functions intended to be copied or sourced into scripts | Includes opinionated system setup helpers such as apt, nginx/apache, certbot, and CMake installation; not a full application framework | Existing Bash automation that wants lightweight helpers plus server/deployment utilities |
| [bash-lib](https://aks.github.io/bash-lib/) | Modular Bash utility library with individual utility files and test scripts | General-purpose Bash function collection; modular sourcing; regression-test orientation | Broader library layout with many separately sourced utility files; less focused on web/server provisioning helpers | Projects that want a more structured collection of Bash utility modules |
| [BSFL](https://github.com/SkypLabs/bsfl) | One-file Bash Shell Function Library for output, logging, command handling, timers, arrays, and network helpers | Sourceable function library for common Bash scripting tasks | More focused on script presentation/logging/runtime helpers; does not aim to provide the same deployment-specific helpers | Scripts that mainly need polished terminal output, logging, and common runtime helpers |
| [Bash Infinity](https://invent.life/project/bash-infinity-framework/) | Bash standard-library and boilerplate framework with modular features | Provides reusable Bash features and can be introduced gradually | More framework-oriented than `rbashutils`; emphasizes boilerplate structure, error handling, and imports | New CLI tools that benefit from a framework-style project structure |
| [Alinex BashLib 2](https://alinex.gitlab.io/bash-lib/) | Structured Bash framework for readable local, remote, interactive, and automated scripts | Covers common shell-script concerns such as logging, option parsing, output formatting, and automation workflows | Larger and more prescriptive framework; includes conventions for remote/server workflows | Larger operations scripts where consistency, structure, and framework conventions are more important than minimal footprint |
| [bash-boilerplate](https://github.com/xwmx/bash-boilerplate) | Boilerplate for safer standalone Bash command-line programs | Provides reusable patterns for safer Bash scripts | More template/pattern library than runtime function library; aimed at standalone CLI scripts | Starting a new single-file Bash CLI with strict-mode/help/usage patterns |
| [ShellSpec](https://github.com/shellspec/shellspec) | BDD testing framework for shell scripts | Useful for testing Bash libraries such as `rbashutils` | Testing tool, not a runtime utility library | Projects that need structured shell tests, mocking, or coverage support |
| [shfmt / mvdan/sh](https://github.com/mvdan/sh) | Shell parser, formatter, and related tooling | Useful alongside any shell library to keep scripts consistent | Development tool, not a sourceable library | Formatting and maintaining shell code across a project |

In short: `rbashutils` is closest to a lightweight utility library with some deployment-oriented helpers. Choose a framework such as Bash Infinity or Alinex BashLib when project structure and conventions matter more. Choose BSFL or bash-lib when the need is mostly common Bash helpers. Use ShellSpec and shfmt as complementary development tools rather than replacements.

---

## License

See [LICENSE](LICENSE).
