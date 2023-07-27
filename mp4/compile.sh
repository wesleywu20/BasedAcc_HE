#!/bin/bash

set -e

make cringe # > output.txt
cd bin_new
make run ASM=accel.S
cd ..
make based
