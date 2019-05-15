#!/bin/bash
rm -r _site
dune exec specl
rm -r ../docs
mv _site/snark-challenge ../docs
# rsync -Ar _site/snark-challenge/ ../docs
