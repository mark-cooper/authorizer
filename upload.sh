#!/bin/bash
# ./upload.sh $TYPE $USER $HOST $PORT $PATH

TYPE=${1}
USER=${2}
HOST=${3}
PORT=${4:-22}
PATH=${5:-/tmp/aspace/import}

rsync -rvz -e "ssh -p $PORT" --progress ./data/auth/$TYPE/*.xml $USER@$HOST:/$PATH
