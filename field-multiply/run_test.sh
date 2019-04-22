#!/bin/bash

# Generate input
./generate-inputs/main.py > inputs

# Compile reference

# Run reference
echo "Running reference"
cat inputs | ./reference/main.py > outputs.reference
echo ""

echo "Running slow test"
cat inputs | ./reference/main-slow.py > outputs.test
echo ""


if ! cmp outputs.reference outputs.test; then
    echo 'Outputs differ - invalid test'
else
    echo 'Outputs match - valid test'
fi