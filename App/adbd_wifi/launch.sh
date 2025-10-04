#!/bin/sh
echo ++++++++++++++++++++$0
cd $(dirname "$0")
echo ====================`pwd`
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
./adbd&

