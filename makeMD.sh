#!/bin/bash

# Append .md to each url in a file then create the file. We can then import them
# into joplin for use in our note taking.

rm -f *.md                                      # Tidy up
tr -d $'\r' < list.txt > list.md                # File has ^M, remove the carriage returns
readarray urls <<< $(sed 's|.*|&\.md|' list.md) # Create the inital array of .md filenames
touch ${urls[@]}                                # Create each file in the destination
