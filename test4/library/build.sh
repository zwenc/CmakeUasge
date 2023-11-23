rm -r build
rm -r ../install

mkdir build
cd build

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE:FILEPATH=../mycomplie.toolchain.cmake # 添加这个
make
make install 
cd ..
