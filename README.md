# Unidata Tomcat Docker

[![Travis Status](https://travis-ci.org/Unidata/tomcat-docker.svg?branch=master)](https://travis-ci.org/Unidata/tomcat-docker)

This repository contains files necessary to build and run a security hardened Tomcat Docker container, based off of the canonical [Tomcat base image](https://hub.docker.com/_/tomcat/). The Unidata Tomcat Docker images associated with this repository are [available on Docker Hub](https://hub.docker.com/r/unidata/tomcat-docker/). All default web application have
been expunged from this container so it will primarily serve a base image for other containers.

## Versions

* `unidata/tomcat-docker:latest` (inherits `tomcat:8.5-jre8`)
* `unidata/tomcat-docker:8.5` (inherits `tomcat:8.5-jre8`)
* `unidata/tomcat-docker:8.0` (inherits `tomcat:8.0-jre8`)
* `unidata/tomcat-docker:8` (deprecated though matches `unidata/tomcat-docker:8.0` for the time being)

## Security Hardening Measures

This Tomcat container was security hardened according to [OWASP recommendations](https://www.owasp.org/index.php/Securing_tomcat). Specifically,

- Eliminated default Tomcat web applications
- Run Tomcat with unprivileged user `tomcat` (via `entrypoint.sh`)
- Start Tomcat via Tomcat Security Manager (via `entrypoint.sh`)
- All files in `CATALINA_HOME` are owned by user `tomcat` (via `entrypoint.sh`)
- Files in `CATALINA_HOME/conf` are read only (`400`) by user `tomcat` (via `entrypoint.sh`)
- Server version information is obscured to user
- Stack traces are not returned to user
- Add secure flag in cookie
- Container-wide `umask` of `007`

### Digested Passwords

This container has a `UserDatabaseRealm`, `Realm` element in `server.xml` with a default `CredentialHandler` algorithm of `SHA`. This modification is an improvement over the clear text password default that comes with the parent container (`tomcat:8.5-jre8`). Passwords defined in `tomcat-users.xml` must use digested passwords in the `password` attributes of the `user` elements. Generating a digested password is simple. Here is an example for the `SHA` digest algorithm:

```bash
docker run tomcat  /usr/local/tomcat/bin/digest.sh -a "SHA" mysupersecretpassword
```

This command will yield something like:

```bash
mysupersecretpassword:94e334bc71163a69f2e984e73741f610e083a8e11764ee3e396f6935c3911f49$1$a5530e17501f83a60286f6363a8647a277c9cfdb
```
The hash after the `:` is what you will use for the `password` attribute in `tomcat-users.xml`.

More information about this topic is available in the [Tomcat documentation](https://tomcat.apache.org/tomcat-8.5-doc/realm-howto.html#Digested_Passwords).

## HTTP Over SSL

This Tomcat container can support HTTP over SSL. For example, generate a self-signed certificate with `openssl` (or better yet, obtain a real certificate from a certificate authority):

```bash
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj \
    "/C=US/ST=Colorado/L=Boulder/O=Unidata/CN=tomcat.example.com" -keyout \
    ./ssl.key -out ./ssl.crt
```

Then augment the `server.xml` from this repository with this additional XML snippet for [Tomcat SSL capability](https://tomcat.apache.org/tomcat-8.0-doc/ssl-howto.html):

```xml
<Connector port="8443"
       maxThreads="150"
       enableLookups="false"
       disableUploadTimeout="true"
       acceptCount="100"
       scheme="https"
       secure="true"
       SSLEnabled="true"
       SSLCertificateFile="${catalina.base}/conf/ssl.crt"
       SSLCertificateKeyFile="${catalina.base}/conf/ssl.key" />
```

Mount over the existing `server.xml` and add the SSL certificate and private key with:

```bash
docker run -it -d  -p 80:8080 -p 443:8443 \
    -v /path/to/server.xml:/usr/local/tomcat/conf/server.xml \
    -v /path/to/ssl.crt:/usr/local/tomcat/conf/ssl.crt \
    -v /path/to/ssl.key:/usr/local/tomcat/conf/ssl.key \
    unidata/tomcat-docker:8
```

or if using `docker-compose` the `docker-compose.yml` will look like:

```yaml
unidata-tomcat:
  image: unidata/tomcat-docker:8
  ports:
    - "80:8080"
    - "443:8443"
  volumes:
    - /path/to/ssl.crt:/usr/local/tomcat/conf/ssl.crt
    - /path/to/ssl.key:/usr/local/tomcat/conf/ssl.key
    - /path/to/server.xml:/usr/local/tomcat/conf/server.xml
```
## Configurable Tomcat UID and GID

The problem with mounted Docker volumes and UID/DIG mismatch headaches is best explained here: https://denibertovic.com/posts/handling-permissions-with-docker-volumes/.

This container allows the possibility of controlling the UID/GID of the `tomcat` user inside the container via `TOMCAT_USER_ID` and `TOMCAT_GROUP_ID` environment variables. If not set, the default UID/GID is `1000`/`1000`. For example,


```bash
docker run --name tomcat \
     -e TOMCAT_USER_ID=`id -u` \
     -e TOMCAT_GROUP_ID=`getent group $USER | cut -d':' -f3` \
     -v `pwd`/logs:/usr/local/tomcat/logs/ \
     -v  /path/to/your/webapp:/usr/local/tomcat/webapps \
     -d -p 8080:8080 unidata/tomcat-docker:latest
```

where `TOMCAT_USER_ID` and `TOMCAT_GROUP_ID` have been configured with the UID/GID of the user running the container. If using `docker-compose`, see `compose.env` to configure the UID/GID of user `tomcat` inside the container. 

This feature enables greater control of file permissions written outside the container via mounted volumes (e.g., files contained within the Tomcat logs directory such as `catalina.out`).

Note that containers that inherit this container and have overridden `entrypoint.sh` will have to take into account user `tomcat` is no longer assumed in the `Dockerfile`. Rather the `tomcat` user is now created within the `entrypoint.sh` and those overriding `entrypoint.sh` should take this fact into account.

Also note that this UID/GID configuration option will not work on operating systems where Docker is not native (e.g., macOS).
