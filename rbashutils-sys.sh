#!/bin/bash

# Sets the domain name in the host file
# @param [in] string - Domain name
setDomain()
{
    local DOMAINNAME=$1
    if [ -z $DOMAINNAME ]; then
        exitWithError "Domain name not specified"
    fi

    local CURDOMAIN=$(hostname)
    local CURDOMAINF=$(hostname -f)
    if [[ "$CURDOMAIN" != "$DOMAINNAME" ]] || [[ "$CURDOMAINF" != "$DOMAINNAME" ]]; then

        showInfo "Setting hostname..."

        if ! isCmd "docker"; then
            hostname -F $DOMAINNAME
            hostnamectl set-hostname $DOMAINNAME
            systemctl restart systemd-hostnamed
        fi

        # Update hosts file
        sed -i "s/127.0.0.1.*$DOMAINNAME.*//g" /etc/hosts
        sed -i "s/127.0.0.1.*localhost.*/127.0.0.1    $DOMAINNAME\n127.0.0.1    localhost/g" /etc/hosts

    fi
fi

