#!/bin/bash

USAGE="
dockertags  --  list all tags for a Docker image in the DockerHub registry \n
\n
INPUTS: \n
./dockertags -u|--user <user> \ \n
    -p|--password <password> \ \n
    -n|--namespace <namespace> \ \n
    -i|--image <image> \ \n
    [ -h|--help ] \n
\n
--user: username used for authentication to dockerhub registry \n
--password: password or personal access token \n
--namespace: organization name (e.g. "unidata"); "library" for public repos \n
--image: the name of the image \n
--help: print this help message and exit \n
\n
OUTPUTS: \n
The tags of the desired image, each on a new line. For example: \n
\n
$ ./dockertags --user $USERNAME \ \n
    --password $PASSWORD \ \n
    --namespace library \ \n
    --image $IMAGE \n
\n
tag1 \n
tag2 \n
tag3 \n
"

while [[ $# > 0 ]]
do
    key="$1"
    case $key in
        -u|--user)
            USERNAME="$2"
            shift # past argument
            ;;
        -p|--password)
            PASSWORD="$2"
            shift # past argument
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift # past argument
            ;;
        -i|--image)
            IMAGE="$2"
            shift # past argument
            ;;
        -h|--help)
            echo -e $USAGE
            exit
            ;;
    esac
    shift # past argument or value
done

# Check if all values were set
[[ -z "$USERNAME" ]] && { echo -e "Must supply a username...Exiting" $USAGE; exit 1; }
[[ -z "$PASSWORD" ]] && { echo -e "Must supply a password...Exiting" $USAGE; exit 1; }
[[ -z "$NAMESPACE" ]] && { echo -e "Must supply a namespace...Exiting" $USAGE; exit 1; }
[[ -z "$IMAGE" ]] && { echo -e "Must supply an image...Exiting" $USAGE; exit 1; }

# Grab a token for authentiting when querying the registry
token=$(curl -Ls -X POST https://hub.docker.com/v2/users/login \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" | jq -r .token)

# Query the registry for the first 100 entries (the maximum page size)
RESPONSE=$(curl -Ls -G \
    --data-urlencode "page_size=100" \
    --data-urlencode "page=1" \
    -H "Authorization: Bearer ${token}" \
    https://hub.docker.com/v2/namespaces/${NAMESPACE}/repositories/${IMAGE}/tags)

# Parse using jq
TAGS=$(echo $RESPONSE | jq '.results[].name')

# If more than 100 tags exist in the repository, we must loop through all pages
# using the "next" field of the JSON response
let PAGE=1
NEXTURL=$(echo $RESPONSE | jq '.next')

while [[ "${NEXTURL}" != "null" ]];
do
    let PAGE+=1
    RESPONSE=$(curl -Ls -G \
        --data-urlencode "page_size=100" \
        --data-urlencode "page=$PAGE" \
        -H "Authorization: Bearer ${token}" \
        https://hub.docker.com/v2/namespaces/${NAMESPACE}/repositories/${IMAGE}/tags)
        TAGS+=" $(echo $RESPONSE | jq '.results[].name')"
    NEXTURL=$(echo $RESPONSE | jq '.next')
done

# Print each tag on its own line and remove quotes (") from around each tag
printf '%s\n' $TAGS | sed -e 's/"//g'
