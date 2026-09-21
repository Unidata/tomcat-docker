#!/bin/bash
set -e

# Start Tomcat via start-tomcat.sh; inheriting containers can also use catalina.sh.

if [ "$1" = 'start-tomcat.sh' ] || [ "$1" = 'catalina.sh' ]; then

    USER_ID=${TOMCAT_USER_ID:-1000}
    GROUP_ID=${TOMCAT_GROUP_ID:-1000}

    case "$USER_ID" in
        (''|*[!0-9]*)
            echo "ERROR: TOMCAT_USER_ID must be numeric, got '$USER_ID'" >&2;
                      exit 1;;
    esac
    case "$GROUP_ID" in
        (''|*[!0-9]*)
            echo "ERROR: TOMCAT_GROUP_ID must be numeric, got '$GROUP_ID'" >&2;
                      exit 1;;
    esac
    if [ "$USER_ID" -eq 0 ] || [ "$GROUP_ID" -eq 0 ]; then
       echo "ERROR: TOMCAT_USER_ID and TOMCAT_GROUP_ID must be non-root" >&2
       exit 1
    fi

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

    # Give the Tomcat runtime user ownership only of standard writable directories.
    # Do not change ownership or permissions elsewhere in CATALINA_HOME.
    for dir in logs temp work; do
        if [ -d "${CATALINA_HOME}/${dir}" ]; then
            chown -R "$USER_ID:$GROUP_ID" "${CATALINA_HOME}/${dir}"
        fi
    done

    exec gosu $USER_ID "$@"
fi

exec "$@"
