cmake_minimum_required(VERSION 2.8)
include(ExternalProject)
project(DS2I)

configure_file(
  ${DS2I_SOURCE_DIR}/ds2i_config.hpp.in
  ${DS2I_SOURCE_DIR}/ds2i_config.hpp
  ESCAPE_QUOTES)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()

if (UNIX)
   # C++14
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

   # For hardware popcount and other special instructions
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")

   # Extensive warnings
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wno-missing-braces -Wno-unused-parameter")
   # Silence a warning bug in Boost
   if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
     set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-local-typedefs")
   endif ()
   # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wconversion")

   if (USE_SANITIZERS)
     set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fno-omit-frame-pointer")
   endif ()

   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ggdb") # Add debug info anyway

endif()

# set(Boost_USE_STATIC_LIBS ON)
find_package(Boost 1.53.0 COMPONENTS iostreams unit_test_framework filesystem system thread REQUIRED)
#set(Boost_INCLUDE_DIRS $ENV{HOME}/include) # Add debug info anyway
#set(Boost_LIBRARIES $ENV{HOME}/lib)
include_directories(${Boost_INCLUDE_DIRS})
link_directories(${Boost_LIBRARY_DIRS})

# stxxl
add_definitions(-DSTXXL_VERBOSE_LEVEL=-10) # suppress messages to stdout
add_subdirectory(stxxl)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${STXXL_CXX_FLAGS}")
include_directories(${STXXL_INCLUDE_DIRS})

# add the root directory to include path to make includes absolute
include_directories(${DS2I_SOURCE_DIR})
add_subdirectory(succinct EXCLUDE_FROM_ALL)
add_subdirectory(FastPFor EXCLUDE_FROM_ALL)

# Indri
externalproject_add(indri_proj
    SOURCE_DIR ${CMAKE_HOME_DIRECTORY}/indri
    CONFIGURE_COMMAND ./configure
    BUILD_IN_SOURCE 1
    BUILD_COMMAND make
    INSTALL_COMMAND ""
    )
file(MAKE_DIRECTORY ${CMAKE_HOME_DIRECTORY}/indri/contrib/antlr/obj)
file(MAKE_DIRECTORY ${CMAKE_HOME_DIRECTORY}/indri/contrib/lemur/obj)
file(MAKE_DIRECTORY ${CMAKE_HOME_DIRECTORY}/indri/contrib/xpdf/obj)
file(MAKE_DIRECTORY ${CMAKE_HOME_DIRECTORY}/indri/obj)
set(INDRI_INCLUDE_DIRS
    ${CMAKE_HOME_DIRECTORY}/indri/include
    ${CMAKE_HOME_DIRECTORY}/indri/contrib/antlr/include
    ${CMAKE_HOME_DIRECTORY}/indri/contrib/lemur/include
    ${CMAKE_HOME_DIRECTORY}/indri/contrib/xpdf/include
    ${CMAKE_HOME_DIRECTORY}/indri/contrib/zlib/include
    )
include_directories(${INDRI_INCLUDE_DIRS})
set(INDRI_LIB_DIR ${CMAKE_HOME_DIRECTORY}/indri)
add_library(indri STATIC IMPORTED)
set_target_properties(indri PROPERTIES IMPORTED_LOCATION ${INDRI_LIB_DIR}/obj/libindri.a)
add_library(lemur STATIC IMPORTED)
set_target_properties(lemur PROPERTIES IMPORTED_LOCATION ${INDRI_LIB_DIR}/contrib/lemur/obj/liblemur.a)
add_library(antlr STATIC IMPORTED)
set_target_properties(antlr PROPERTIES IMPORTED_LOCATION ${INDRI_LIB_DIR}/contrib/antlr/obj/libantlr.a)
add_library(xpdf STATIC IMPORTED)
set_target_properties(xpdf PROPERTIES IMPORTED_LOCATION ${INDRI_LIB_DIR}/contrib/xpdf/obj/libxpdf.a)
# binaries that link libindri.a need these flags set
set(INDRI_DEP_FLAGS "-DHAVE_EXT_ATOMICITY=1 -DP_NEEDS_GNU_CXX_NAMESPACE=1")

add_executable(create_freq_index create_freq_index.cpp wand_data.hpp)
target_link_libraries(create_freq_index
  ${Boost_LIBRARIES}
  FastPFor_lib
  )

add_executable(optimal_hybrid_index optimal_hybrid_index.cpp)
target_link_libraries(optimal_hybrid_index
  ${Boost_LIBRARIES}
  FastPFor_lib
  ${STXXL_LIBRARIES}
  )

add_executable(create_wand_data create_wand_data.cpp)
target_link_libraries(create_wand_data
  ${Boost_LIBRARIES}
  )

add_executable(queries queries.cpp)
target_link_libraries(queries
  ${Boost_LIBRARIES}
  FastPFor_lib
  )

add_executable(trec_queries trec_queries.cpp)
target_link_libraries(trec_queries
  ${Boost_LIBRARIES}
  FastPFor_lib
  )


add_executable(dump_rm dump_rm.cpp docvector/compress_qmx.cpp)
target_link_libraries(dump_rm
  ${Boost_LIBRARIES}
  FastPFor_lib
  )


add_executable(single_shot_expansion single_shot_expansion.cpp docvector/compress_qmx.cpp)
target_link_libraries(single_shot_expansion
  ${Boost_LIBRARIES}
  FastPFor_lib
  )

add_executable(external_corpora_expansion external_corpora_expansion.cpp docvector/compress_qmx.cpp)
target_link_libraries(external_corpora_expansion
  ${Boost_LIBRARIES}
  FastPFor_lib
  )

add_executable(external_corpus_expansion external_corpus_expansion.cpp docvector/compress_qmx.cpp)
target_link_libraries(external_corpus_expansion
  ${Boost_LIBRARIES}
  FastPFor_lib
  pthread
  )

add_executable(train_corpus_sampler train_corpus_sampler.cpp docvector/compress_qmx.cpp)
target_link_libraries(train_corpus_sampler
  ${Boost_LIBRARIES}
  FastPFor_lib
  pthread
  )


add_executable(external_corpus_sampler external_corpus_sampler.cpp docvector/compress_qmx.cpp)
target_link_libraries(external_corpus_sampler
  ${Boost_LIBRARIES}
  FastPFor_lib
  pthread
  )


add_executable(profile_decoding profile_decoding.cpp)
target_link_libraries(profile_decoding
  ${Boost_LIBRARIES}
  FastPFor_lib
  )

add_executable(shuffle_docids shuffle_docids.cpp)
target_link_libraries(shuffle_docids
  ${Boost_LIBRARIES}
  FastPFor_lib
  )

add_executable(indri_to_ds2i format_index/indri_to_ds2i.cpp)
set_target_properties(indri_to_ds2i PROPERTIES COMPILE_FLAGS ${INDRI_DEP_FLAGS})
add_dependencies(indri_to_ds2i indri_proj)
target_link_libraries(indri_to_ds2i
    indri
    lemur
    pthread
    z
    m
)

include_directories(${CMAKE_HOME_DIRECTORY}/docvector)
add_executable(create_docvectors
    docvector/create_docvectors.cpp
    docvector/compress_qmx.cpp
    docvector/create_docvectors.cpp
)
#target_link_libraries(create_docvectors m)

# XXX Rodger: Disabled tests as they wouldn't build
#enable_testing()
#add_subdirectory(test)
add_subdirectory(benchmarks)
