#!/bin/sh

curl -o ./.travis/actual.html http://127.0.0.1:8080/sample/index.html

diff ./.travis/expected.html ./.travis/actual.html

cmp ./.travis/expected.html ./.travis/actual.html
