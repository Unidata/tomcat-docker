# Usage:
# ./findTomcatVersion.sh <desired-major-tomcat-version> <desired-jdk-version>

# Regex explanation
# ^\( *${MAJORTOMCATVERSION}[.-]\) ---- Find ${MAJORTOMCATVERSION} at the /beginning/ of the search string, followed by either a "." or a "-"; ignore leading white space
# \([0-9]*[.-]\)* ---- Any number of digits from 0-9, followed by a "." or a "-"; find this expression 0 or more times
# \(jdk${JDKVERSION}-openjdk\)$ ---- Find the following string at the /end/ of the search string

MAJORTOMCATVERSION=$1
JDKVERSION=$2

set -o pipefail

awk -F "/" '{print $NF}' | \
grep "\(^\( *${MAJORTOMCATVERSION}\)[.-]\)\([0-9]*[.-]\)*\(jdk${JDKVERSION}-openjdk\)$" | \
sort -Vr | \
head -n1
