rm -r build

mkdir build
cd build

cmake .. \
    -Dmysum_DIR:PATH="/home/wp/code/cmake/CmakeUasge/test3/install/share/cmake/mysum" # 要加上这句，find_package才能找到，名字必须是${lib_name}_DIR
make

cd ..

./build/app