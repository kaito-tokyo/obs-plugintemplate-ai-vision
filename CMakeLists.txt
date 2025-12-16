cmake_minimum_required(VERSION 3.28)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/common")
include(init)

project(${PLUGIN_NAME} VERSION ${PLUGIN_VERSION} LANGUAGES C CXX)

option(BUILD_TESTING "Build test cases" ON)

if(MSVC)
  list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/windows")
elseif(APPLE)
  list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/macos")
else()
  list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/linux")
endif()

include(compilerconfig)
include(defaults)
include(helpers)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED TRUE)
set(CMAKE_C_EXTENSIONS FALSE)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(CMAKE_CXX_EXTENSIONS FALSE)

set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN TRUE)

list(
  PREPEND
  CMAKE_PREFIX_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/.deps/Frameworks"
  "${CMAKE_CURRENT_SOURCE_DIR}/.deps"
  "${CMAKE_CURRENT_SOURCE_DIR}/.deps/obs-deps-qt6-2025-07-11-universal"
  "${CMAKE_CURRENT_SOURCE_DIR}/.deps/obs-deps-2025-07-11-universal"
)

if(MSVC)
  list(
    PREPEND
    CMAKE_PREFIX_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/.deps/obs-deps-qt6-${QT6_VERSION}-x64"
    "${CMAKE_CURRENT_SOURCE_DIR}/.deps/obs-deps-${PREBUILT_VERSION}-x64"
  )
elseif(APPLE)
  list(
    PREPEND
    CMAKE_PREFIX_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/.deps/obs-deps-qt6-${QT6_VERSION}-universal"
    "${CMAKE_CURRENT_SOURCE_DIR}/.deps/obs-deps-${PREBUILT_VERSION}-universal"
  )
endif()

find_package(libobs REQUIRED)
find_package(obs-frontend-api REQUIRED)
find_package(Qt6 COMPONENTS Widgets Core REQUIRED)

set(PLUGIN_SOURCES src/plugin-main.cpp)

add_library(${CMAKE_PROJECT_NAME} MODULE ${PLUGIN_SOURCES})
target_link_libraries(${CMAKE_PROJECT_NAME} OBS::libobs OBS::obs-frontend-api Qt6::Widgets Qt6::Core)
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE "PLUGIN_VERSION=\"${PLUGIN_VERSION}\"")

if(MSVC)
  target_sources(${CMAKE_PROJECT_NAME} PRIVATE "${CMAKE_SOURCE_DIR}/cmake/windows/resources/export_symbols.def")
elseif(APPLE)
  target_link_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE "-Wl,-exported_symbols_list,${CMAKE_SOURCE_DIR}/cmake/macos/resources/exported_symbols_list.txt"
  )
  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@loader_path/../Frameworks"
  )
else()
  target_link_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE "-Wl,--version-script,${CMAKE_SOURCE_DIR}/cmake/linux/resources/version_script.map"
  )
endif()

set_target_properties_plugin(${CMAKE_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${CMAKE_PROJECT_NAME})

if(BUILD_TESTING)
  enable_testing()
endif()
