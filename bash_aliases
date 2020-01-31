#!/bin/bash

function cs () {
    cd "$@" && ls
    }
    
alias git-addcommit="git add -A && git commit -m"