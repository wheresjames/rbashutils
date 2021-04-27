#!/bin/bash

# Parses a domain name
# @param [in] string - Domain name
#
# @example
#
#   PARSED=$(parseDomain www.example.com)
#
#   output > www example.com
#
parseDomain()
{
    local DOMAINNAME="$1"

    local DOMAINARR=(${DOMAINNAME//./ })
    local DOTNAME=${DOMAINARR[0]}
    local ROOTARR=${DOMAINARR[@]:1}
    local DOMAINROOT=${ROOTARR// /.}

    echo "$DOTNAME $DOMAINROOT"
}

#
# Compress a web site
#
# @example
#
#   # Initialize
#   initCompress
#
#   # Compress the web folder
#   compressWeb "$SRCDIR" "$DSTDIR"
#   if [ ! -d "$DSTDIR" ]; then
#       exitWithError "Failed to compress $SRCDIR -> $DSTDIR"
#   fi
#

# Download specified file
# @param [in] string - Tool name
# @param [in] string - URL Link to tool
downloadTool()
{
    local TOOLNAME=$1
    local TOOLURL=$2
    local TOOLDNL=$3

    local TOOLEXEC="${RBASHUTIL_TOOLPATH}/${TOOLNAME}"

    if [ -f $TOOLEXEC ]; then
        echo "$TOOLEXEC"
        return 0
    fi

    # Tool path
    if [ ! -d "$RBASHUTIL_TOOLPATH" ]; then
        mkdir -p "$RBASHUTIL_TOOLPATH"
        exitOnError "Failed to create path : $RBASHUTIL_TOOLPATH"
    fi

    # Download the tool if we don't have it
    curl -L $TOOLURL -o $TOOLEXEC
    exitOnError "CURL failed to download $TOOLNAME"
    if [ ! -f $TOOLEXEC ]; then
        exitWithError "Failed to download $TOOLNAME"
    fi

    echo "$TOOLEXEC"
    return 0
}

# @param [in] string - Tool file name
# @param [in] string - grep pattern to find exec in zip
# @param [in] string - URL to zip file
# @returns Path to tool exec
downloadToolCompressed()
{
    local TOOLNAME=$1
    local TOOLGREP=$2
    local TOOLURL=$3

    local TOOLEXEC="${RBASHUTIL_TOOLPATH}/${TOOLNAME}"

    # Already exists?
    if [ -f "${TOOLEXEC}" ]; then return 0; fi

    local TOOLEXT="${TOOLURL##*.}"

    # Remove existing
    local TMPZIP="${RBASHUTIL_TOOLPATH}/tmp.${TOOLEXT}"
    if [ -f "$TMPZIP" ]; then
        rm "$TMPZIP"
    fi

    # Download the archive
    downloadTool "tmp.${TOOLEXT}" "$TOOLURL" "$TMPZIP"
    if [ ! -f "$TMPZIP" ]; then
        exitWithError "Failed to download tool $TOOLNAME"
    fi

    # Lose old path
    local TMPZIPPATH="${RBASHUTIL_TOOLPATH}/tmp-${TOOLEXT}"
    if [ -d "$TMPZIPPATH" ]; then
        rm -Rf "$TMPZIPPATH"
    fi

    # Create path to extract files
    mkdir -p "$TMPZIPPATH"
    exitOnError "Failed to create path : $TMPZIPPATH"

    # Extract tool
    case ${TOOLEXT,,} in
        "zip")
            unzip "$TMPZIP" -d "$TMPZIPPATH"
        ;;
        *)
            exitWithError "Unknown archive type : ${TOOLEXT,,}"
        ;;
    esac

    # Find the file
    local TOOLFIND=$(find $TMPZIPPATH | grep -E $TOOLGREP | head -1)
    if [ -z $TOOLFIND ] || [ ! -f $TOOLFIND ]; then
        exitWithError "Failed to find in archive : $TOOLGREP -> $TOOLNAME"
    fi

    # Copy the exe we found
    mv "$TOOLFIND" "$TOOLEXEC"

    # Cleanup
    rm "$TMPZIP"
    rm -Rf "$TMPZIPPATH"

    echo "$TOOLEXEC"
    return 0
}

# Download compression tools
#
# @notes sets global variables JAVAEXEC, CCEXEC, MINEXEC, YUIEXEC
initCompress()
{
    JAVAEXEC=$(which java)
    if [[ -z "$JAVAEXEC" ]] || [[ ! -f "$JAVAEXEC" ]]; then
        exitWithError "Java not installed"
    fi

    # Closure compiler (old)
    # CCEXEC=$(downloadToolCompressed "cc.jar" "closure-compiler" "https://dl.google.com/closure-compiler/compiler-latest.zip")
    # if [[ -z "$CCEXEC" ]] || [[ ! -f "$CCEXEC" ]]; then
    #     exitWithError "Failed to install closure compiler"
    # fi

    # Closure compiler
    CCEXEC=$(downloadTool "cc.jar" "https://repo1.maven.org/maven2/com/google/javascript/closure-compiler/v20201102/closure-compiler-v20201102.jar")
    if [[ -z "$CCEXEC" ]] || [[ ! -f "$CCEXEC" ]]; then
        exitWithError "Failed to install closure compiler"
    fi

    # HTML Minifier
    MINEXEC=$(which html-minifier)
    if [[ -z "$MINEXEC" ]] || [[ ! -f "$MINEXEC" ]]; then
        npm install html-minifier -g
        exitOnError "Failed to install html-minifier"
    fi

    YUIEXEC=$(downloadTool "yui.jar" "https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar")
    if [[ -z "$YUIEXEC" ]] || [[ ! -f "$YUIEXEC" ]]; then
        exitWithError "Failed to install yuicompressor"
    fi

    showVars - JAVAEXEC CCEXEC MINEXEC YUIEXEC
}


# Compresses a web site
# @param [in] string - Input directory
# @param [in] string - Output directory
# @param [internal]  - Total number of files
# @param [internal]  - Current file count
compressWeb()
{
    local IND=$1
    local OUTD=$2
    local TOT=$3
    local CNT=$4

    # showInfo "- Compressing : $IND"

    if [[ $IND =~ ".." ]]; then
        exitWithError "Invalid source directory : $IND"
    fi

    if [ ! -d "$IND" ]; then
        exitWithError "Directory doesn't exist : $IND"
    fi

    if [[ $OUTD =~ ".." ]]; then
        exitWithError "Invalid destination directory : $OUTD"
    fi

    if [ ! -d "$OUTD" ]; then
        mkdir -p $OUTD
        exitOnError "Failed to create directory : $OUTD"
    fi

    if [ -z "$TOT" ]; then
        TOT=$(countFiles "$IND" YES)
        CNT="RBASHUTILS_COMPRESSWEB_$(getPassword 8)"
        declare -g $CNT=0
    fi

    local FILES=$IND/*

    for SRC in $FILES
    do
        # Empty
        if [[ $SRC =~ "*" ]]; then
            echo "Skipping Empty directory : $SRC"
            continue
        fi

        local FNAME=`basename $SRC`
        local TGT=$OUTD/$FNAME

        local PROG="[ -- ]"
        declare -g $CNT=$((${!CNT}+1))
        if [[ 0 -lt $TOT ]]; then
            local PERCENT=$((${!CNT} * 100 / $TOT))
            if [[ 0 -gt $PERCENT ]]; then PERCENT=0;
            elif [[ 100 -lt $PERCENT ]]; then PERCENT=100; fi
            PROG="[$(padStrLeft "$PERCENT" 3)%]"
        fi

        if [ -d $SRC ]; then

            compressWeb $SRC $TGT $TOT $CNT

        # Is it already minimized?
        elif [[ $SRC =~ ".min." ]]; then

            echo "$PROG Copy Minimized File : $SRC -> $TGT"

            cp "$SRC" "$TGT"
            exitOnError "(d) Failed to copy $SRC -> $TGT"

        # Process this file
        else

            local EXT="${FNAME##*.}"

            echo "$PROG $EXT : $SRC -> $TGT"

            case ${EXT,,} in

                "js")
                    $JAVAEXEC -jar $CCEXEC  --warning_level quiet --js_output_file "$TGT" --js "$SRC"
                    if [[ 0 -ne $? ]]; then
                        echo "!!! Failed to build $SRC"
                        cp "$SRC" "$TGT"
                        exitOnError "(js) Failed to copy $SRC -> $TGT"
                    fi
                ;;

                "css")
                    $JAVAEXEC -jar $YUIEXEC -o "$TGT" "$SRC"
                    if [[ 0 -ne $? ]]; then
                        echo "!!! Failed to build $SRC"
                        cp "$SRC" "$TGT"
                        exitOnError "(css) Failed to copy $SRC -> $TGT"
                    fi
                ;;

                "htm" | "html")
                    $MINEXEC --collapse-whitespace -o "$TGT" "$SRC"
                    if [[ 0 -ne $? ]]; then
                        echo "!!! Failed to build $SRC"
                        cp "$SRC" "$TGT"
                        exitOnError "(html) Failed to copy $SRC -> $TGT"
                    fi
                ;;

                *)
                    cp "$SRC" "$TGT"
                    exitOnError "(*) Failed to copy $SRC -> $TGT"
                ;;

            esac

        fi

    done

    return 1
}

# Create self signed cert
# @param [in] string - Domain name
# @param [in] string - Certificate output directory
# @param [in] string - Certificate info
#
# https://stackoverflow.com/questions/10175812/how-to-create-a-self-signed-certificate-with-openssl
#
createSelfSignedCert()
{
    local DOMAINNAME=$1
    local CERTDIR=$2
    local CERTINFO=$3

    if [[ -z $CERTDIR ]]; then
        CERTDST="./certs/${DOMAINNAME}"
    fi

    if [[ -z $CERTINFO ]]; then
        CERTINFO="/C=US/ST=NY/L=NY/O=${DOMAINNAME}/OU=Org/CN=${DOMAINNAME}/emailAddress=cert@${DOMAINNAME}"
    fi

    local KEYSIZE="rsa:2048"
    # local KEYSIZE="rsa:4096"

    # Get new credentials
    if [[ -d "$CERTDIR" ]]; then
        showInfo "Already have self signed cert for ${DOMAINNAME} in ${CERTDIR}"
    else
        showInfo "Creating self signed certificate..."
        mkdir -p $CERTDIR
        openssl req -x509 -newkey $KEYSIZE -nodes \
                    -keyout "$CERTDIR/privkey.pem" \
                    -out "$CERTDIR/chain.pem" \
                    -days 365 \
                    -subj "$CERTINFO"
        if [[ 0 -ne $? ]]; then
            rm -Rf "$CERTDIR"
            exitOnError "Error creating self-signed cert for localhost"
        fi
    fi
}

# Create certificate request
# @param [in] string - Domain name
# @param [in] string - Certificate output directory
# @param [in] string - Certificate password
# @param [in] string - Certificate info
#
# https://stackoverflow.com/questions/10175812/how-to-create-a-self-signed-certificate-with-openssl
#
createCertRequest()
{
    local DOMAINNAME=$1
    local CERTDIR=$2
    local CERTPASS=$3
    local CERTINFO=$4

    if [[ -z $CERTDIR ]]; then
        CERTDST="./certs/${DOMAINNAME}"
    fi

    if [[ -z $CERTINFO ]]; then
        CERTINFO="/C=US/ST=NY/L=NY/O=${DOMAINNAME}/OU=Org/CN=${DOMAINNAME}/emailAddress=cert@${DOMAINNAME}"
    fi

    # Get new credentials
    if [[ -d "$CERTDIR" ]]; then
        showInfo "Already have certificate request for ${DOMAINNAME} in ${CERTDIR}"
    else
        showInfo "Creating certificate request..."

        if [[ -z $CERTPASS ]]; then
            CERTPASS=$(getPassword 32 "${DOMAINNAME}" "$CERTDIR")
        fi

        # Create key
        openssl genrsa -des3 -passout pass:$CERTPASS -out "$CERTDIR/privkey.key" 2048 -noout
        openssl rsa -in "$CERTDIR/privkey.key" -passin pass:$CERTPASS -out "$CERTDIR/privkey.key"

        #Create request
        openssl req -new -key "$CERTDIR/privkey.key" -out "$CERTDIR/certreq.csr" -passin pass:$CERTPASS -subj "$CERTINF"
    fi
}


# Installs letsencrypt cert
# @param [in] string - Domain name
# @param [in] int    - Maximum retries on failure
# @param [in] string - "dummy" = Resubmit with dummy domain name to
#                                get around rate limit.
#
# https://letsencrypt.org/docs/rate-limits/
# https://crt.sh
#
createLetsencryptCert()
{
    local DOMAINNAME=$1
    local CERTRETRY=$2
    local OPTS=$3

    if [[ -z $DOMAINNAME ]]; then exitWithError "Domain name not specified"; fi
    if [[ -z $CERTRETRY ]]; then CERTRETRY=1; fi

    local LETSDIR="/etc/letsencrypt/live"
    local CACHEDIR="/ssl/cache/live"
    local CERTDIR="$LETSDIR/${DOMAINNAME}"

    aptInstall "software-properties-common"
    aptInstall "letsencrypt"
    aptInstall "certbot"

    # Add renew job to cron
    if ! findIn "crontab -l" "certbot"; then
        local CERTRENEW="0 12 * * * /usr/bin/certbot renew --quiet"
        (crontab -l; echo "$CERTRENEW" ) | crontab -
    fi

    # See if we have cached credentials
    if [[ ! -d "$CERTDIR" ]]; then
        if [[ -f "$CACHEDIR/${DOMAINNAME}/fullchain.pem" ]]; then
            showInfo "Copying cached credentials for ${DOMAINNAME}..."
            mkdir -p "$LETSDIR"
            cp -R "$CACHEDIR/${DOMAINNAME}" "$CERTDIR"
        fi
    fi

    # Get new credentials
    if [[ -d "$CERTDIR" ]]; then

        showInfo "Already have cert for ${DOMAINNAME}"

    else

        showInfo "Setting up SSL..."

        doIfNot "ufw show added" "80/tcp" "ufw allow 80/tcp"

        local RESTARTAPACHE=
        if findIn "ps cax" "apache2"; then
            showWarning "Stopping apache, it will be restarted"
            systemctl stop apache2
            RESTARTAPACHE="systemctl start apache2"
            sleep 3
        fi

        local RESTARTNGINX=
        if findIn "ps cax" "nginx"; then
            showWarning "Stopping nginx, it will be restarted"
            systemctl stop nginx
            RESTARTNGINX="systemctl start nginx"
            sleep 3
        fi

        local DUMMYNAME=
        while [ 0 -lt $CERTRETRY ]; do

            showInfo "Requesting a certificate using letsencrypt certbot..."
            certbot certonly --standalone --preferred-challenges http-01 \
                            --agree-tos --no-eff-email -m cert@${DOMAINNAME} \
                            -d ${DOMAINNAME} ${DUMMYNAME}

            if [[ 0 -ne $? ]]; then
                CERTRETRY=$((CERTRETRY-1))
                if [ $CERTRETRY -le 0 ]; then
                    showError "letsencrypt certbot failed"
                else
                    showWarning "letsencrypt certbot failed, retrying in 30 seconds"
                    sleep 30
                    if [[ $OPTS == "dummy" ]]; then
                        local RANDOMSTR=$(getPassword 8)
                        local PARSED=($(parseDomain ${DOMAINNAME}))
                        DUMMYNAME="-d ${PARSED[0]}-${RANDOMSTR}.${PARSED[1]}"
                    fi
                fi
            else
                CERTRETRY=0
                showInfo "letsencrypt certbot succeeded"
            fi
        done

        $RESTARTAPACHE
        $RESTARTNGINX
    fi
}

# Install UFW firewall
installUfw()
{
    showInfo "Setting up firewall (ufw)..."

    aptInstall "ufw"

    # Add rules
    doIfNot "ufw show added" "22/tcp" "ufw allow 22/tcp"

    # Ensure 22 is in there so we don't get locked out
    if ! findIn "ufw show added" "22/tcp"; then
        ufw show added
        exitWithError "Failed to add ssh to firewall (ufw)"
    fi

    doIf "ufw status" "inactive" "ufw enable" "yes"

    sed -i "0,/#& stop/s//& stop/" /etc/rsyslog.d/20-ufw.conf

    systemctl restart rsyslog
}

# Default nginx install
# @param [in] string - Domain name
# @param [in] string - "ssl" = Configure SSL
installNginx()
{
    local DOMAINNAME=$1
    local SETUPTYPE=$2

    showInfo "Configure nginx..."

    if isCommand "ufw"; then
        doIfNot "ufw show added" "80/tcp" "ufw allow 80/tcp"
        doIfNot "ufw show added" "443/tcp" "ufw allow 443/tcp"
    fi

    apt-get -yq install nginx

    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        rm "/etc/nginx/sites-enabled/default"
    fi

    local CFG_SSL=
    if [[ "ssl" == $SETUPTYPE ]]; then
        CFG_SSL="\n
                listen 443 ssl;\n
                # include /etc/letsencrypt/options-ssl-nginx.conf;\n
                ssl_certificate /etc/letsencrypt/live/${DOMAINNAME}/fullchain.pem;\n
                ssl_certificate_key /etc/letsencrypt/live/${DOMAINNAME}/privkey.pem;\n
                if (\$scheme = \"http\") {\n
                    return 301 https://\$host\$request_uri;\n
                }\n
        "
    fi

    local CFG_BASE_SITE="\n
        server {\n
            listen 80 default_server;\n
            listen [::]:80 default_server;\n
            \n
            server_name ${DOMAINNAME};\n
            \n
                $CFG_SSL\n
            \n
            location / {\n
                return 403;\n
            }\n
            \n
            location /ws/ {\n
                proxy_pass          http://127.0.0.1:8080/;\n
            }
            \n
            location = /ws {\n
                proxy_pass          http://127.0.0.1:8080/;\n
                proxy_read_timeout  90;\n
                \n
                proxy_set_header    Host \$host;\n
                proxy_set_header    X-Real-IP \$remote_addr;\n
                proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;\n
                proxy_set_header    X-Forwarded-Proto \$scheme;\n
                \n
                proxy_http_version  1.1;\n
                proxy_set_header    Upgrade \$http_upgrade;\n
                proxy_set_header    Connection \"upgrade\";\n
                proxy_cache_bypass  1;\n
                proxy_no_cache      1;\n
            }\n
        }\n
    "
    echo -e ${CFG_BASE_SITE} > /etc/nginx/conf.d/${DOMAINNAME}.conf

    nginx -t
    exitOnError "Error in nginx configuration"

    nginx -s reload
    exitOnError "Failed to restart nginx"
}

# Default apache install
# @param [in] string - Domain name
# @param [in] string - "ssl" = Configure SSL
installApache()
{
    local DOMAINNAME=$1
    local SETUPTYPE=$2

    showInfo "Installing apache"

    systemctl stop apache2

    if isCommand "ufw"; then
        doIfNot "ufw show added" "80/tcp" "ufw allow 80/tcp"
        doIfNot "ufw show added" "443/tcp" "ufw allow 443/tcp"
    fi

    apt-get install -yq apache2
    exitOnError "Failed to install apache"

    if [[ ! -d "/var/www/${DOMAINNAME}" ]]; then
        mkdir -p "/var/www/${DOMAINNAME}"
    fi

    if [[ ! -f "/var/www/${DOMAINNAME}/index.html" ]]; then
        echo "401 - ACCESS DENIED" > "/var/www/${DOMAINNAME}/index.html"
    fi

    local CFG_BASE_SITE="\n
        <VirtualHost *:80>\n
            ServerName ${DOMAINNAME}\n
            Redirect / https://${DOMAINNAME}\n
        </VirtualHost>
        \n
        <VirtualHost _default_:443>\n
            ServerName ${DOMAINNAME}\n
            DocumentRoot /var/www/${DOMAINNAME}\n
            SSLEngine On\n
            SSLCertificateFile /etc/letsencrypt/live/${DOMAINNAME}/fullchain.pem\n
            SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAINNAME}/privkey.pem\n
            ErrorLog \${APACHE_LOG_DIR}/${DOMAINNAME}_error.log\n
            CustomLog \${APACHE_LOG_DIR}/${DOMAINNAME}_access.log combined\n
        </VirtualHost>\n
    "
    echo -e ${CFG_BASE_SITE} > /etc/apache2/sites-available/${DOMAINNAME}.conf

    a2enmod ssl
    warnOnError "Failed to enable apache ssl"

    a2dissite 000-default

    a2ensite ${DOMAINNAME}
    warnOnError "Failed to enable site ${DOMAINNAME}"

    # systemctl reload apache2
    systemctl start apache2
}
