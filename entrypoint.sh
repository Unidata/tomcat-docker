#!/bin/bash
set -e

# preferable to fire up Tomcat via start-tomcat.sh which will start Tomcat with
# security manager, but inheriting containers can also start Tomcat via
# catalina.sh

if [ "$1" = 'start-tomcat.sh' ] || [ "$1" = 'catalina.sh' ]; then

    USER_ID=${TOMCAT_USER_ID:-1000}
    GROUP_ID=${TOMCAT_GROUP_ID:-1000}

    ###
    # Tomcat user
    ###
    # create group for GROUP_ID if one doesn't already exist
    if ! getent group $GROUP_ID &> /dev/null; then
      groupadd -r tomcat -g $GROUP_ID
    fi
    # create user for USER_ID if one doesn't already exist
    if ! getent passwd $USER_ID &> /dev/null; then
      useradd -u $USER_ID -g $GROUP_ID tomcat
    fi
    # alter USER_ID with nologin shell and CATALINA_HOME home directory
    usermod -d "${CATALINA_HOME}" -s /sbin/nologin $(id -u -n $USER_ID)

    ###
    # Change CATALINA_HOME ownership to tomcat user and tomcat group
    # Restrict permissions on conf
    ###

    chown -R $USER_ID:$GROUP_ID ${CATALINA_HOME} && find ${CATALINA_HOME}/conf \
        -type d -exec chmod 755 {} \; -o -type f -exec chmod 400 {} \;
    sync

    ###
    # Deactivate CORS filter in web.xml if DISABLE_CORS=1
    # Useful if CORS is handled outside of Tomcat (e.g. in a proxying webserver like nginx)
    ###
    if [ "$DISABLE_CORS" == "1" ]; then
      echo "Deactivating Tomcat CORS filter"
      sed -i 's/<!-- CORS_START.*/<!-- CORS DEACTIVATED BY DISABLE_CORS -->\n<!--/; s/^.*<!-- CORS_END -->/-->/' \
        ${CATALINA_HOME}/conf/web.xml
    fi

    exec gosu $USER_ID "$@"
fi

exec "$@"
