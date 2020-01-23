#!/bin/bash

set -o errexit # added || true to commands that are allowed to fail.

((!$#)) && echo No arguments supplied! && exit 1 # Exit in the absence of any arguments







if [ -z ${var+x} ];
then
    echo "var is unset";
else
    echo "var is set to '$var'";
fi
