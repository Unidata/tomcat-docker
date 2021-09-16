- [Unidata Tomcat Docker](#h-CBB85014)
  - [Versions](#h-E01B4A0F)
  - [Security Hardening Measures](#h-C9AD76A0)
    - [web.xml Enhancements](#h-1BF7025D)
    - [server.xml Enhancements](#h-BC90DBB0)
    - [Digested Passwords](#h-2C497D80)
  - [HTTPS](#h-E0520F81)
    - [Self-signed Certificates](#h-AA504A54)
    - [Certificate from CA](#h-0B755481)
  - [Configurable Tomcat UID and GID](#h-688F3648)



<a id="h-CBB85014"></a>

# Unidata Tomcat Docker

This repository contains files necessary to build and run a security hardened Tomcat Docker container, based off of the canonical [Tomcat base image](https://hub.docker.com/_/tomcat/). The Unidata Tomcat Docker images associated with this repository are [available on Docker Hub](https://hub.docker.com/r/unidata/tomcat-docker/). All default web application have been expunged from this container so it will primarily serve a base image for other containers.


<a id="h-E01B4A0F"></a>

## Versions

-   `unidata/tomcat-docker:latest` (inherits `tomcat:8.5-jdk8-openjdk`)
-   `unidata/tomcat-docker:8.5` (inherits `tomcat:8.5-jdk8-openjdk`)


<a id="h-C9AD76A0"></a>

## Security Hardening Measures

This Tomcat container was security hardened according to [OWASP recommendations](https://www.owasp.org/index.php/Securing_tomcat). Specifically,

-   Eliminated default Tomcat web applications
-   Run Tomcat with unprivileged user `tomcat` (via `entrypoint.sh`)
-   Start Tomcat via Tomcat Security Manager (via `entrypoint.sh`)
-   All files in `CATALINA_HOME` are owned by user `tomcat` (via `entrypoint.sh`)
-   Files in `CATALINA_HOME/conf` are read only (`400`) by user `tomcat` (via `entrypoint.sh`)
-   Container-wide `umask` of `007`


<a id="h-1BF7025D"></a>

### web.xml Enhancements

The following changes have been made to [web.xml](./web.xml) from the out-of-the-box version:

-   Added `SAMEORIGIN` anti-clickjacking option
-   HTTP header security filter (`httpHeaderSecurity`) uncommented/enabled
-   Cross-origin resource sharing (CORS) filtering (`CorsFilter`) added/enabled
-   Stack traces are not returned to user through `error-page` element.


<a id="h-BC90DBB0"></a>

### server.xml Enhancements

The following changes have been made to [server.xml](./server.xml) from the out-of-the-box version:

-   Server version information is obscured to user via `server` attribute for all `Connector` elements
-   `secure` attribute set to `true` for all `Connector` elements
-   Shutdown port disabled
-   Digested passwords. See next section.

The active `Connector` has `relaxedPathChars` and `relaxedQueryChars` attributes. This change may not be optimal for security, but must be done [to accommodate DAP requests](https://github.com/Unidata/thredds-docker/issues/209) which THREDDS and RAMADDA must perform.


<a id="h-2C497D80"></a>

### Digested Passwords

This container has a `UserDatabaseRealm`, `Realm` element in `server.xml` with a default `CredentialHandler` `algorithm` of `sha-512`. This modification is an improvement over the clear text password default that comes with the parent container (`tomcat:8.5-jre8`). Passwords defined in `tomcat-users.xml` must use digested passwords in the `password` attributes of the `user` elements. Generating a digested password is simple. Here is an example for the `sha-512` digest algorithm:

```sh
docker run tomcat  /usr/local/tomcat/bin/digest.sh -a "sha-512" mysupersecretpassword
```

This command will yield something like:

```sh
mysupersecretpassword:94e334bc71163a69f2e984e73741f610e083a8e11764ee3e396f6935c3911f49$1$a5530e17501f83a60286f6363a8647a277c9cfdb
```

The hash after the `:` is what you will use for the `password` attribute in `tomcat-users.xml`.

More information about this topic is available in the [Tomcat documentation](https://tomcat.apache.org/tomcat-8.5-doc/realm-howto.html#Digested_Passwords).


<a id="h-E0520F81"></a>

## HTTPS

This Tomcat container can support HTTPS for either self-signed certificates which can be useful for experimentation or certificates from a CA for a production server. For a complete treatment on this topic, see <https://tomcat.apache.org/tomcat-8.5-doc/ssl-howto.html>.


<a id="h-AA504A54"></a>

### Self-signed Certificates

This Tomcat container can support HTTP over SSL. For example, generate a self-signed certificate with `openssl` (or better yet, obtain a real certificate from a certificate authority):

```sh
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

```sh
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


<a id="h-0B755481"></a>

### Certificate from CA

First, obtain a certificate from a certificate authority (CA). This process will yield a `.key` and `.crt` file. To meet enhanced security guidelines you, will want serve a certificate with the intermediate certificates present in the `ssl.crt` file. For Tomcat to serve the certificate chain, you have to put your `.key` and `.crt` (containing the intermediate certificates) in a Java keystore.

First put the `.key` and `.crt` in a `.p12` file:

```sh
openssl pkcs12 -export -in ssl.crt.fullchain -inkey ssl.key -out ssl.p12 -name \
    mydomain.com
```

Then add the `.p12` file to the keystore:

```
keytool -importkeystore -destkeystore keystore.jks -srckeystore ssl.p12 \
    -srcstoretype PKCS12
```

When prompted for passwords in the two steps above, consider reusing the same password to reduce cognitive load.

You'll then refer to that keystore in your `server.xml`:

```xml
<Connector port="8443"
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           clientAuth="false"
           sslProtocol="TLSv1.2, TLSv1.3"
           ciphers="ECDHE-ECDSA-AES128-GCM-SHA256,ECDHE-RSA-AES128-GCM-SHA256,ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES256-GCM-SHA384,ECDHE-ECDSA-CHACHA20-POLY1305,ECDHE-RSA-CHACHA20-POLY1305,DHE-RSA-AES128-GCM-SHA256,DHE-RSA-AES256-GCM-SHA384"
           maxThreads="150"
           enableLookups="false"
           disableUploadTimeout="true"
           acceptCount="100"
           scheme="https"
           secure="true"
           SSLEnabled="true"
           keystoreFile="${catalina.base}/conf/keystore.jks"
           keyAlias="mydomain.com"
           keystorePass="xxxx"
           />
```

Note there are a few differences with the `Connector` described for the self-signed certificate above. These additions are made according to enhanced security guidelines.

Mount over the existing `server.xml` and add the SSL certificate and private key with:

```sh
docker run -it -d  -p 80:8080 -p 443:8443 \
    -v /path/to/server.xml:/usr/local/tomcat/conf/server.xml \
    -v /path/to/ssl.jks:/usr/local/tomcat/conf/ssl.jks \
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
    - /path/to/ssl.jks:/usr/local/tomcat/conf/ssl.jks
    - /path/to/server.xml:/usr/local/tomcat/conf/server.xml
```


<a id="h-688F3648"></a>

## Configurable Tomcat UID and GID

The problem with mounted Docker volumes and UID/DIG mismatch headaches is best explained here: <https://denibertovic.com/posts/handling-permissions-with-docker-volumes/>.

This container allows the possibility of controlling the UID/GID of the `tomcat` user inside the container via `TOMCAT_USER_ID` and `TOMCAT_GROUP_ID` environment variables. If not set, the default UID/GID is `1000/1000`. For example,

```sh
docker run --name tomcat \
     -e TOMCAT_USER_ID=`id -u` \
     -e TOMCAT_GROUP_ID=`getent group $USER | cut -d':' -f3` \
     -v `pwd`/logs:/usr/local/tomcat/logs/ \
     -v  /path/to/your/webapp:/usr/local/tomcat/webapps \
     -d -p 8080:8080 unidata/tomcat-docker:latest
```

where `TOMCAT_USER_ID` and `TOMCAT_GROUP_ID` have been configured with the UID/GID of the user running the container. If using `docker-compose`, see `compose.env` to configure the UID/GID of user `tomcat` inside the container.

This feature enables greater control of file permissions written outside the container via mounted volumes (e.g., files contained within the Tomcat logs directory such as `catalina.out`).

Note that containers that inherit this container and have overridden `entrypoint.sh` will have to take into account user `tomcat` is no longer assumed in the `Dockerfile`. Rather the `tomcat` user is now created within the `entrypoint.sh` and those overriding `entrypoint.sh` should take this fact into account. Also note that this UID/GID configuration option will not work on operating systems where Docker is not native (e.g., macOS).
