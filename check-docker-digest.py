#!/usr/bin/env python3

# Can put this Python script in cron, e.g.,
#
# 0 */12 * * * /home/user/tomcat-docker/check-docker-digest.py
# >> /tmp/tomcat-cron.out 2>&1

import requests
import datetime

DIGEST_FILE_PATH = "/tmp/tomcat-image-digest.txt"
REPOSITORY = "library/tomcat"
TAG = "8.5-jdk11"
TARGET_ARCHITECTURE = "amd64"


def get_image_manifest(repository, tag):
    dockerhub_url = "https://registry-1.docker.io"
    auth_url = "https://auth.docker.io/token"
    repo_scope = f"repository:{repository}:pull"

    # Get the authentication token
    response = requests.get(auth_url,
                            params={'service': 'registry.docker.io',
                                    'scope': repo_scope})
    response.raise_for_status()
    token = response.json()['token']

    # Get the image manifest list
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.docker.distribution.manifest.list.v2+json'
    }
    response = requests.get(f'{dockerhub_url}/v2/{repository}/manifests/{tag}',
                            headers=headers)
    response.raise_for_status()

    return response.json()


def get_image_digest_for_architecture(manifest_list, architecture):
    for manifest in manifest_list['manifests']:
        if (manifest['platform']['architecture'] == architecture
                and manifest['platform']['os'] == 'linux'):
            return manifest['digest']
    return None


def read_digest_from_file(file_path):
    with open(file_path, 'r') as file:
        return file.read().strip()


def write_digest_to_file(file_path, digest):
    with open(file_path, 'w') as file:
        file.write(digest)


# Read the current digest from the file
try:
    current_digest = read_digest_from_file(DIGEST_FILE_PATH)
except FileNotFoundError:
    print(f"Digest file not found at {DIGEST_FILE_PATH}. "
          f"Creating a new file...")
    current_digest = ""

# Fetch the new digest from DockerHub
manifest_list = get_image_manifest(REPOSITORY, TAG)
new_digest = get_image_digest_for_architecture(manifest_list,
                                               TARGET_ARCHITECTURE)

# Compare and update the digest if different
if new_digest != current_digest:
    now = datetime.datetime.now()
    print(f"New digest found: {new_digest} at {now}")
    write_digest_to_file(DIGEST_FILE_PATH, new_digest)
    requests.get("https://maker.ifttt.com/trigger/tomcat/with/key/"
                 "xxx")
    print(f"Updated digest in {DIGEST_FILE_PATH}")
else:
    print("Digests are the same. No update needed.")
