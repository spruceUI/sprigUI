#!/bin/sh

cd $(dirname "$0")
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
./adbd &
