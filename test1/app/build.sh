rm -r build

mkdir build
cd build

cmake ..
make

cd ..

./build/app