# 设置 CMake 的 toolchain 文件
# 此文件用于定义编译器和相关设置

# 指定编译器

# 可以修改编译器，可以改成各种芯片的交叉编译器
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CMAKE_CXX_COMPILER "/usr/bin/g++")

# 指定 C++ 标准
set(CMAKE_CXX_STANDARD 20)	  # 使用C++20标准
set(CMAKE_BUILD_TYPE Debug)   # DEBUG 还是 Release 模式放到这里设置

# 优化级别
set(CMAKE_CXX_FLAGS "-O2")    # 开启02优化
set(BUILD_SHARED_LIBS ON)     # 默认是动态库