cmake_minimum_required(VERSION 3.18)
set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "" FORCE)

project(Cider_CXXNativeUtils LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)

include(FetchContent)

FetchContent_Declare(
        wxWidgets
        GIT_REPOSITORY https://github.com/wxWidgets/wxWidgets.git
)
FetchContent_GetProperties(wxwidgets)
if(NOT wxwidgets_POPULATED)
    set(wxWidgets_USE_STATIC 1)
    set(wxBUILD_SHARED OFF)
    FetchContent_Populate(wxwidgets)
    add_subdirectory(${wxwidgets_SOURCE_DIR} ${wxwidgets_BUILD_DIR})
endif()

file(GLOB_RECURSE SOURCES "cxx/*.cpp" "cxx/*.h")
add_library(${PROJECT_NAME} STATIC ${SOURCES})

target_include_directories(${PROJECT_NAME} PRIVATE ${wxWidgets_SOURCE_DIR}/include)
target_link_libraries(${PROJECT_NAME} PRIVATE wx::base wx::core)