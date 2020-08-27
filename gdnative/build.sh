#!/bin/bash

function check_dependency {
    if ![command -v "$1" >/dev/null 2>&1]; then
        echo "Missing dependency. Please make sure $1 is installed."
        exit
    fi
}

check_dependency scons

echo "======Building PokerHandEvaluator======"
mkdir PokerHandEvaluator/cpp/build
cp phe.patch PokerHandEvaluator/cpp/build/
cd PokerHandEvaluator/cpp/build/
patch -d.. -p2 <phe.patch
cmake ..
make

echo "======Building libHandEval======"
cd ../../..
scons platform=linux