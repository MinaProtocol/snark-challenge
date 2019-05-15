#!/bin/bash

set -euo pipefail

for workdir in ../reference-*
do
    echo "----------------------------------------"
    echo "** Workdir: $workdir"
    pushd $workdir > /dev/null


    if [[ -f main ]] && [[ -f generate_inputs ]]; then
	echo '** Binaries detected - Skipping build'
    else
	echo '** Building'
	./build.sh
    fi
    
    if [[ -f inputs ]]; then
	echo '** Inputs detected - Skipping generation'
    else
	echo "** Generating inputs"
	time ./generate_inputs 2>&1
    fi
	
    echo "** Checking inputs"
    sha256sum inputs
    
    echo "** Running main program"
    time ./main compute inputs outputs 2>&1

    echo "** Checking outputs"
    sha256sum outputs

    popd > /dev/null
    
done
