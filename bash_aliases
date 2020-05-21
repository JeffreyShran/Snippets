#!/bin/bash

function cs () {
    cd "$@" && ls
    }
    
alias git-addcommit="git add -A && git commit -m"

function findTargetUrl () {
    find /mnt/e/GDrive/YNAW/HackWiki/Programs -type d -name "*$1*" -exec basename {} \;
}
