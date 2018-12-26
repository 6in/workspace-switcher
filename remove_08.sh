#!/bin/bash

cat $1 | perl -pe 's/\x08//g' > test.txt & mv test.txt $1.new

