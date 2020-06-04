#!/bin/bash

# test file for fileChecker function

if [[ -e $1 && -s $1 ]]; # file exists and is not zero size
then
if grep -qsF "null" <(head -n 1 $1);
then
    echo "file exists and is not zero size but contains the word 'null' on line 1"
else
    echo "file exists and is not zero size & does not contain the word 'null' on line 1"
fi
else
echo "file does not exist or is zero size"
fi