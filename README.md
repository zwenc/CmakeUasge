> 省流：3.2和 4.2 必看，其它的都是推导过度

<a name="xnwJf"></a>
# 一、基本流程
（信息 待补充）
<a name="wqH94"></a>
# 二、分模块用法
> 工程地址：[https://github.com/zwenc/CmakeUasge/tree/main/test1](https://github.com/zwenc/CmakeUasge/tree/main/test1)

目录结构如下：
```bash
├── CMakelists.txt			// cmake 文件 1, 负责生成可执行文件
├── build.sh				// 包含执行cmake的那几个指令，我不想手动敲，就都写在这里了
├── include
│   └── temp.h				// 头文件
├── main.cpp                // 源文件 1  main 函数在这里
└── subfolder
    ├── CMakelists.txt		// cmake 文件 2, 负责将当前目录下的cpp文件编译成lib库
    └── temp.cpp			// 源文件 2  库 里面有个打印字符串的函数
```
**核心问题：**

1. 两个cmake文件如何联合合作
   1. cmake 1  和 2  变量是否共享。 答：可以
   2. cmake 1 如何拿到cmake 2 编译好的lib库。见下面两个make的实现

build.sh内容（没有特别说明的地方，build.sh的内容是一样的）：
```bash
rm -r build
rm -r ../install  # app文件夹里面build.sh没有这句话

mkdir build
cd build

cmake ..
make
make install      # app文件夹里面build.sh没有这句话

cd ..
```

**最简cmake如下：**<br />cmake 1
```cmake
cmake_minimum_required(VERSION 3.16.3)

# 可以看到这里甚至没有任何CXX这样的编译参数
# 如果没有任何编译器相关的参数，则使用默认
# 这样对于写test的cmake非常友好，不需要特别严谨
# 如何优雅的添加的各种编译器参数，见第四章

project(hello)

include_directories(./include)

add_subdirectory(subfolder)  # 在这个位置会自动引用subfolder下的CMakeLists.txt 文件

add_executable(app main.cpp) # 生成可执行文件
target_link_libraries(app temp)
```
cmake 2
```cmake
# 生成temp lib库，共享了Cmake 1中的include_directories结果
# 这里的源文件地址是相对于cmake2文件地址的，而不是cmake1。 这就非常的nice
add_library(temp temp.cpp)   
```
**优点：**<br />子目录的cmake2写法简单，可以由各级目录自己控制，并且也会单独生成一个lib库，便于后期调试。<br />我的建议是，在分配任务的时候，每个人负责那的那片空间写一个cmake文件。

**本例特点：**<br />虽然上面的例子分了两个模块，但是本质上还是在同一个project中。

**问题：**

1. 不同工程的库，如何**优雅**的链接编译。见第三章
2. 如何优雅的跟换不同的编译器（支持多平台）。见第四章
<a name="iI2GU"></a>
# 三、第三方库如何优雅编译链接
核心问题：

1. 第三方库该如何生成
2. 第三方库如何连接到可执行文件中
<a name="co5f8"></a>
## 3.1 常规方法
> 工程地址：[https://github.com/zwenc/CmakeUasge/tree/main/test2](https://github.com/zwenc/CmakeUasge/tree/main/test2)

工程文件结构如下：
```bash
├── app
│   ├── CMakelists.txt
│   ├── build.sh
│   ├── include
│   │   └── temp.h
│   ├── main.cpp
│   └── subfolder
│       ├── CMakelists.txt
│       └── temp.cpp
└── library
    ├── CMakelists.txt
    ├── build.sh
    ├── include
    │   └── mysum.h
    └── src
        └── mysum.cpp
```
<a name="g2wtq"></a>
### 3.1.1 库的生成
库结构单独列出来：
```bash
├── CMakelists.txt
├── build.sh
├── include
│   └── mysum.h
└── src
    └── mysum.cpp
```
**cmake的写法：**
```cmake

cmake_minimum_required(VERSION 3.16.3)

project(sum)

# install的时候，目录以这个作为相对地址，它默认值为系统目录
# 如果不想安装在系统目录，该参数建议设置
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_LIST_DIR}/../install)

# 编译类型，非必须参数，但建议填写。
set(CMAKE_BUILD_TYPE Debug)

include_directories(./include)		 # 头文件地址
add_library(mysum src/mysum.cpp)   # 这个位置会生成musum lib库，放在编译目录下，如build

# 下面两个在执行 make install 的时候会把库copy到对应位置
install(TARGETS mysum
    ARCHIVE DESTINATION lib # 如果mysum是静态库，则拷贝到${CMAKE_INSTALL_PREFIX}/lib
    LIBRARY DESTINATION lib # 如果mysum是动态库，则拷贝到${CMAKE_INSTALL_PREFIX}/lib
    RUNTIME DESTINATION bin # 如果mysum是可执行文件，则拷贝到${CMAKE_INSTALL_PREFIX}/bin
)

# 拷贝头文件到${CMAKE_INSTALL_PREFIX}/include
install(
		# 这个目录其实是build里面的，因为在make之后，修改build/include的值
    # 再make install, 会影响install的结果
    DIRECTORY include/     
    DESTINATION include/
)

```
**执行cmake，make，make install后，工程目录结构:**
```bash
├── app
│   ├── CMakelists.txt
│   ├── build.sh
│   ├── include
│   │   └── temp.h
│   ├── main.cpp
│   └── subfolder
│       ├── CMakelists.txt		  
│       └── temp.cpp
├── install											# 生成了这个文件夹，里面有库和头文件
│   ├── include
│   │   └── mysum.h
│   └── lib
│       └── libmysum.a
└── library
    ├── CMakelists.txt
    ├── build.sh
    ├── include
    │   └── mysum.h
    └── src
        └── mysum.cpp
```
<a name="EusuV"></a>
### 3.1.2 库的链接
**附上app/CMakelists.txt的写法：**

```cmake
cmake_minimum_required(VERSION 3.16.3)

project(hello)

include_directories(./include)

include_directories(../install/include)   # 增加库的头文件搜索地址
link_directories(../install/lib)					# 增加库文件搜索地址

add_subdirectory(subfolder)

add_executable(app main.cpp)
target_link_libraries(app temp mysum)     # 链接到可执行文件里面
```
<a name="NBvSx"></a>
### 3.1.3 优缺点
**优点：**<br />简单，易于理解，自己写自己用，非常方便<br />**缺点：**<br />有些库的头文件目录结构会比较复杂，如果这个库是给别人使用，需要配置的信息可能会比较复杂，并且如果还会修改的话（如：静态库变成动态库），两边对接就会不太方便。总之，这种方式不利于合作。<br />所以，理想的方式是配置文件交给库的编写者来实现，这样相对优雅
<a name="oYu2N"></a>
## 3.2 优雅方法 
> 工程地址：[https://github.com/zwenc/CmakeUasge/tree/main/test3](https://github.com/zwenc/CmakeUasge/tree/main/test3)

核心问题：

1. 如何在库编译端生成配置文件
2. User该如何使用这些配置文件

当前目录结构：
```bash
├── app
│   ├── CMakelists.txt
│   ├── build.sh
│   ├── include
│   │   └── temp.h
│   ├── main.cpp
│   └── subfolder
│       ├── CMakelists.txt
│       └── temp.cpp
└── library
    ├── CMakelists.txt
    ├── build.sh
    ├── cmake
    │   └── mysumConfig.cmake.in     # 多了这个文件，非常重要，必须要有
    ├── include
    │   └── mysum.h
    └── src
        └── mysum.cpp
```
<a name="FvshO"></a>
### 3.2.1 库的生成
library文件夹

CMakeLists.txt 内容：
```cmake
cmake_minimum_required(VERSION 3.16.3)

project(sum)

set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_LIST_DIR}/../install)
set(CMAKE_BUILD_TYPE Debug)

## include_directories(./include)		 
add_library(mysum src/mysum.cpp)     
target_include_directories(mysum PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>   # build模式下，该行生效，使用绝对地址
  $<INSTALL_INTERFACE:include/>                            # install模式下，该行神效，使用相对地址
)

install(TARGETS mysum
    EXPORT  mysumTarget       # 输出mysum信息到 mysumTarget 属性中，包含头文件，target等信息
    ARCHIVE DESTINATION lib 
    LIBRARY DESTINATION lib 
    RUNTIME DESTINATION bin 
)

install(                       # 输出 mysumTarget 到文件中
      EXPORT mysumTarget
      DESTINATION  share/cmake/mysum
)

install(
    DIRECTORY include/ 
    DESTINATION include/
)

# 生成配置文件放到 build/mysumConfig.cmake 中
include(CMakePackageConfigHelpers)  # 包含了这个头文件，才能使用下面的方法
configure_package_config_file(
    ${PROJECT_SOURCE_DIR}/cmake/mysumConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/mysumConfig.cmake   # 名字必须是${target_name}Config.cmake, 不然find_package找不到
    INSTALL_DESTINATION share/cmake/mysum           # 地址属性，但是这里不发生拷贝
)

# 拷贝build/mysumConfig.cmake文件到 ${CMAKE_INSTALL_PREFIX}/share/cmake/mysum 中
install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/mysumConfig.cmake 
    DESTINATION share/cmake/mysum
)
```
**mysumConfig.cmake.in 内容：**
```cmake

@PACKAGE_INIT@       # cmake..  后这句话会展开，都需要写

include("${CMAKE_CURRENT_LIST_DIR}/mysumTarget.cmake")  # 头文件，lib库都会在这里加载

```
**在library里面执行./build.sh后，有效的目录结构：**
```bash
├── app
│   ├── CMakelists.txt
│   ├── build.sh
│   ├── include
│   │   └── temp.h
│   ├── main.cpp
│   └── subfolder
│       ├── CMakelists.txt
│       └── temp.cpp
├── install
│   ├── include
│   │   └── mysum.h
│   ├── lib
│   │   └── libmysum.a
│   └── share
│       └── cmake
│           └── mysum        # 多了这个文件夹
│               ├── mysumConfig.cmake     # cmake 里面find_package用到这个文件
│               ├── mysumTarget-debug.cmake  # 这两个Target里面有很多信息，可以读一下
│               └── mysumTarget.cmake
└── library
    ├── CMakelists.txt
    ├── build.sh
    ├── cmake
    │   └── mysumConfig.cmake.in
    ├── include
    │   └── mysum.h
    └── src
        └── mysum.cpp
```
<a name="n1FVJ"></a>
### 3.2.2 库的链接
app文件夹<br />**app/CMakelists.txt内容如下：**
```cmake
cmake_minimum_required(VERSION 3.16.3)

project(hello)

include_directories(./include)

## include_directories(../install/include)   # 现在不需要了，注释
## link_directories(../install/lib)		       # 现在不需要了，注释

find_package(mysum REQUIRED)
if(mysum_FOUND) # mysum_FOUND 这个变量会由上面的find_package自动生成
    message(STATUS "mysum found")
else()
    message(STATUS "mysum not found")
endif()

add_subdirectory(subfolder)

add_executable(app main.cpp)
target_link_libraries(app temp mysum)     # 链接到可执行文件里面

```
**app/build.sh内容如下：**
```bash
rm -r build

mkdir build
cd build

# 要多加一句库地址信息，find_package才能找到，名字必须是${lib_name}_DIR
# 有几种方式可以实现搜索，我觉得这是最合理的方式
cmake .. \
    -Dmysum_DIR:PATH="/home/wp/code/cmake/CmakeUasge/test3/install/share/cmake/mysum" 

make

cd ..

./build/app
```
<a name="Ex0Vk"></a>
### 3.2.3 优缺点
**优点：**<br />便于合作，负责app的人，不需要应为library的目录改动而修改cmake<br />**缺点：**<br />library的cmake将变的有些复杂。
<a name="wrnz3"></a>
# 四、如何优雅的兼容不同平台
> 名词解释：优雅==不需要大改 

> 工程地址：[https://github.com/zwenc/CmakeUasge/tree/main/test4](https://github.com/zwenc/CmakeUasge/tree/main/test4)

<a name="tLtD9"></a>
## 4.1 小细节
注意：前面的编译从来没有设置任何编译器相关的信息，如果要改编译器或者编译信息怎么办
<a name="ccvCz"></a>
## 4.2 修改编译信息
**目录结构：**
```bash
├── app
│   ├── CMakelists.txt
│   ├── build.sh
│   ├── include
│   │   └── temp.h
│   ├── main.cpp
│   └── subfolder
│       ├── CMakelists.txt
│       └── temp.cpp
├── library
│   ├── CMakelists.txt
│   ├── build.sh  # 修改了这个文件
│   ├── cmake
│   │   └── mysumConfig.cmake.in
│   ├── include
│   │   └── mysum.h
│   └── src
│       └── mysum.cpp
└── mycomplie.toolchain.cmake # 新增了这个文件
```

**新增文件mycomplie.toolchain.cmake，内容如下：**
```cmake
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
```
**修改./build.sh，内容如下：**
```bash
rm -r build
rm -r ../install

mkdir build
cd build

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE:FILEPATH=../mycomplie.toolchain.cmake  # 添加这个
make
make install 
cd ..
```
如果使用的是3.2的library编写方式，那么其他的不需要修改。

**结果：**<br />通过对mycomplie.toolchain.cmake的修改，可以看到输出结果不同

**如何看具体的配置信息：**<br />在执行`cmake .. `后，在`test4/library/build/CMakeFiles/mysum.dir/flags.make`中可以看到相关修改的配置信息。

<a name="p8oF0"></a>
## 4.3 优缺点
优点：<br />当需要对配置信息进行修改时，只需要改`mycomplie.toolchain.cmake`这个的信息即可。
