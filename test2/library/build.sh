rm -r build
rm -r install

mkdir build
cd build

cmake ..
make
make install 
cd ..
