#!/bin/bash

# Simple script to remove from the list of arguments any references to files that already exist

not_files=""
for f in "$@"
do
	[[ -f $f ]] || not_files="$not_files $f"
done
echo $not_files
