cmake_minimum_required(VERSION 3.10)
project(Hashgen)

set(SOURCES
    hashgen.c
    BLAKE3/c/blake3.c
    BLAKE3/c/blake3_dispatch.c
    BLAKE3/c/blake3_portable.c
)

set(ASM
    BLAKE3/c/blake3_sse2_x86-64_unix.S
    BLAKE3/c/blake3_sse41_x86-64_unix.S
    BLAKE3/c/blake3_avx2_x86-64_unix.S
    BLAKE3/c/blake3_avx512_x86-64_unix.S
)

foreach(src ${ASM})
    get_filename_component(obj ${src} NAME_WE)
    set(obj ${CMAKE_CURRENT_BINARY_DIR}/${obj}.o)
    add_custom_command(
        OUTPUT ${obj}
        COMMAND ${CMAKE_C_COMPILER} -c ${CMAKE_CURRENT_SOURCE_DIR}/${src} -o ${obj}
        DEPENDS ${src}
    )
    list(APPEND ASM_OBJECTS ${obj})
endforeach()

include_directories(BLAKE3/c)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
add_executable(hashgen ${SOURCES} ${ASM_OBJECTS})

