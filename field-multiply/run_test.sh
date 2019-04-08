#!/bin/bash

# Generate input
if [ ! -f inputs ]; then
    ./test-case/main.py > inputs
else
    echo "Inputs already generated."
fi

# Compile reference


# Run reference
echo "Running reference"
cat inputs | ./reference/main.py

echo ""

echo "Running slow reference"
cat inputs | ./reference/main-slow.py
