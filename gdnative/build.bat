echo "======Building PokerHandEvaluator C++ Library======"
mkdir PokerHandEvaluator/cpp/build
cp phe.patch PokerHandEvaluator/cpp/build/
cd PokerHandEvaluator/cpp/build/
git apply -p2 --directory=PokerHandEvaluator/cpp/ phe.patch
cmake ..
make

cd ..\..\..

echo "======Building godot-cpp======"
cd godot-cpp
scons platform=linux generate_bindings=true -j4

cd ..

echo "======Building libHandEval C++ gdnative library======"
scons platform=linux

pause