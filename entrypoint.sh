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
    # Create group for GROUP_ID if one doesn't already exist.
    if ! getent group "$GROUP_ID" &> /dev/null; then
        groupadd -r tomcat -g "$GROUP_ID"
    fi

    # Create user for USER_ID if one doesn't already exist.
    if ! getent passwd "$USER_ID" &> /dev/null; then
        useradd \
            -u "$USER_ID" \
            -g "$GROUP_ID" \
            -d "$CATALINA_HOME" \
            -s /sbin/nologin \
            tomcat
    else
        # Ensure an existing UID uses the requested primary group.
        usermod -g "$GROUP_ID" "$(id -u -n "$USER_ID")"
    fi

    # Give the Tomcat runtime user ownership only of standard writable directories.
    # Do not change ownership or permissions elsewhere in CATALINA_HOME.
    for dir in logs temp work; do
        if [ -d "${CATALINA_HOME}/${dir}" ]; then
            chown -R "$USER_ID:$GROUP_ID" "${CATALINA_HOME}/${dir}"
        fi
    done

    # Give derived images ownership of explicitly declared runtime directories.
    if [ -n "${TOMCAT_ADDITIONAL_WRITABLE_DIRS:-}" ]; then
        CATALINA_HOME_REAL=$(realpath -e -- "$CATALINA_HOME")
        read -r -a ADDITIONAL_WRITABLE_DIRS <<< "$TOMCAT_ADDITIONAL_WRITABLE_DIRS"
        RESOLVED_WRITABLE_DIRS=()

        for dir in "${ADDITIONAL_WRITABLE_DIRS[@]}"; do
            case "$dir" in
                /*)
                    echo "ERROR: TOMCAT_ADDITIONAL_WRITABLE_DIRS entries must be relative: '$dir'" >&2
                    exit 1
                    ;;
            esac
            case "/$dir/" in
                */../*)
                    echo "ERROR: TOMCAT_ADDITIONAL_WRITABLE_DIRS entries must not contain '..': '$dir'" >&2
                    exit 1
                    ;;
            esac

            if ! writable_dir=$(realpath -e -- "${CATALINA_HOME}/${dir}" 2>/dev/null) || [ ! -d "$writable_dir" ]; then
                echo "ERROR: TOMCAT_ADDITIONAL_WRITABLE_DIRS entry is not an existing directory: '$dir'" >&2
                exit 1
            fi

            case "$writable_dir" in
                "$CATALINA_HOME_REAL")
                    echo "ERROR: TOMCAT_ADDITIONAL_WRITABLE_DIRS must not include CATALINA_HOME itself: '$dir'" >&2
                    exit 1
                    ;;
                "$CATALINA_HOME_REAL"/*)
                    ;;
                *)
                    echo "ERROR: TOMCAT_ADDITIONAL_WRITABLE_DIRS entry resolves outside CATALINA_HOME: '$dir'" >&2
                    exit 1
                    ;;
            esac

            RESOLVED_WRITABLE_DIRS+=("$writable_dir")
        done

        for writable_dir in "${RESOLVED_WRITABLE_DIRS[@]}"; do
            chown -R "$USER_ID:$GROUP_ID" "$writable_dir"
        done
    fi

    exec gosu "$USER_ID" "$@"
fi

exec "$@"
