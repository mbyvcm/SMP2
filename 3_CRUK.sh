#!/bin/bash
set -euo pipefail

#Description: CRUK BaseSpace app pipeline
#Author: Sara Rey and Chris Medway
#Status: RELEASE
Version="1.1.2"

# Name of file containing samples to not be uploaded to BaseSpace
NOTBASESPACE=./"not_bs.txt"

# Load pair file name
SAMPLEPAIRS=$(cat "pairFn.txt")


# Remove pairs that are not for analysis in BaseSpace
if [[ -e "$NOTBASESPACE" ]]
	then
		grep -f "$NOTBASESPACE" -v "$SAMPLEPAIRS">"analysed_pairs.txt"
	else
		cat "$SAMPLEPAIRS">"analysed_pairs.txt"
fi


# Load any variables file to obtain worksheet id
. $(ls -d */ | tail -n 1)/*.variables


# Path to node bin directory (do not include trailing /)
NODE="/share/apps/node-distros/node-v6.11.3-linux-x64/bin"


# Path to location of node_modules
NODE_MOD=$(echo $NODE | awk -F '/' 'BEGIN {OFS = FS} NF{NF--; print $0}')


# Make directory for results
mkdir "$worklistId"


# Make directories with the tumour sample id name to put the results in
cut -f1 "analysed_pairs.txt" | xargs -L 1 -i mkdir "$worklistId""/"{}


# Launch node javascript file and pass node path to script
"$NODE"/node ./baseSpace.js "$NODE_MOD" >baseSpace.out 2>baseSpace.err


# Delete temporary file
if [[ -e "pairFn.txt" ]]
	then
		rm "pairFn.txt"
fi


# Move downloaded files into directory with tumour sample name
while read line
	do
		tum=$(printf "$line" | cut -d$'\t' -f1)
		nor=$(printf "$line" | cut -d$'\t' -f2)
		mv "$worklistId"/*"$tum"*.xlsx "$worklistId"/"$tum"
		mv "$worklistId"/*"$tum"*.bam "$worklistId"/"$tum"
		mv "$worklistId"/*"$tum"*.bai "$worklistId"/"$tum"
		mv "$worklistId"/*"$nor"*.bam "$worklistId"/"$tum"
		mv "$worklistId"/*"$nor"*.bai "$worklistId"/"$tum"
done < "analysed_pairs.txt" >3_CRUK_copy.out 2>3_CRUK_copy.err