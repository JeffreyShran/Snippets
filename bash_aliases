#~/.bash_aliases

function cs () {
    cd "$@" && ls
    }
    
alias sublist3r='python /path/to/Sublist3r/sublist3r.py -d '
alias sublist3r-one=". <(cat domains | awk '{print \"sublist3r \"$1 \" -o \" $1 \".txt\"}')"
alias dirsearch='python3 /path/to/dirsearch/dirsearch.py -u '
alias dirsearch-one=". <(cat domains | awk '{print \"dirsearch \"\$1 \" -e *\"}')"
alias openredirect=". <(cat domains | awk '{print \"dirsearch \"\$1 \" -w /path/to/dirsearch/db/open_redirect_wordlist.txt -e *\"}')"
alias git-update="find . -name .git -type d -execdir git --git-dir '{}' fetch --all ';'"
