#!/bin/bash
rm -r _site
dune exec specl
rsync -Ar _site/snark-challenge/ ../docs
