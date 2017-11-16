#!/bin/sh -x

# docker build . -t rdm7
docker run -v `pwd`:/v -w /v rdm7 sh build.sh
