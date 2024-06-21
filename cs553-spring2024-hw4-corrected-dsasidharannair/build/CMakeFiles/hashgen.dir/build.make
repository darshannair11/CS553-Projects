# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.22

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/cc

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/cc/build

# Include any dependencies generated for this target.
include CMakeFiles/hashgen.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/hashgen.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/hashgen.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/hashgen.dir/flags.make

blake3_sse2_x86-64_unix.o: ../BLAKE3/c/blake3_sse2_x86-64_unix.S
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating blake3_sse2_x86-64_unix.o"
	/usr/bin/cc -c /home/cc/BLAKE3/c/blake3_sse2_x86-64_unix.S -o /home/cc/build/blake3_sse2_x86-64_unix.o

blake3_sse41_x86-64_unix.o: ../BLAKE3/c/blake3_sse41_x86-64_unix.S
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Generating blake3_sse41_x86-64_unix.o"
	/usr/bin/cc -c /home/cc/BLAKE3/c/blake3_sse41_x86-64_unix.S -o /home/cc/build/blake3_sse41_x86-64_unix.o

blake3_avx2_x86-64_unix.o: ../BLAKE3/c/blake3_avx2_x86-64_unix.S
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Generating blake3_avx2_x86-64_unix.o"
	/usr/bin/cc -c /home/cc/BLAKE3/c/blake3_avx2_x86-64_unix.S -o /home/cc/build/blake3_avx2_x86-64_unix.o

blake3_avx512_x86-64_unix.o: ../BLAKE3/c/blake3_avx512_x86-64_unix.S
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Generating blake3_avx512_x86-64_unix.o"
	/usr/bin/cc -c /home/cc/BLAKE3/c/blake3_avx512_x86-64_unix.S -o /home/cc/build/blake3_avx512_x86-64_unix.o

CMakeFiles/hashgen.dir/hashgen.c.o: CMakeFiles/hashgen.dir/flags.make
CMakeFiles/hashgen.dir/hashgen.c.o: ../hashgen.c
CMakeFiles/hashgen.dir/hashgen.c.o: CMakeFiles/hashgen.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building C object CMakeFiles/hashgen.dir/hashgen.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/hashgen.dir/hashgen.c.o -MF CMakeFiles/hashgen.dir/hashgen.c.o.d -o CMakeFiles/hashgen.dir/hashgen.c.o -c /home/cc/hashgen.c

CMakeFiles/hashgen.dir/hashgen.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/hashgen.dir/hashgen.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/cc/hashgen.c > CMakeFiles/hashgen.dir/hashgen.c.i

CMakeFiles/hashgen.dir/hashgen.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/hashgen.dir/hashgen.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/cc/hashgen.c -o CMakeFiles/hashgen.dir/hashgen.c.s

CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o: CMakeFiles/hashgen.dir/flags.make
CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o: ../BLAKE3/c/blake3.c
CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o: CMakeFiles/hashgen.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building C object CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o -MF CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o.d -o CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o -c /home/cc/BLAKE3/c/blake3.c

CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/cc/BLAKE3/c/blake3.c > CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.i

CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/cc/BLAKE3/c/blake3.c -o CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.s

CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o: CMakeFiles/hashgen.dir/flags.make
CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o: ../BLAKE3/c/blake3_dispatch.c
CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o: CMakeFiles/hashgen.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building C object CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o -MF CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o.d -o CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o -c /home/cc/BLAKE3/c/blake3_dispatch.c

CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/cc/BLAKE3/c/blake3_dispatch.c > CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.i

CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/cc/BLAKE3/c/blake3_dispatch.c -o CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.s

CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o: CMakeFiles/hashgen.dir/flags.make
CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o: ../BLAKE3/c/blake3_portable.c
CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o: CMakeFiles/hashgen.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Building C object CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o -MF CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o.d -o CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o -c /home/cc/BLAKE3/c/blake3_portable.c

CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/cc/BLAKE3/c/blake3_portable.c > CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.i

CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/cc/BLAKE3/c/blake3_portable.c -o CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.s

# Object files for target hashgen
hashgen_OBJECTS = \
"CMakeFiles/hashgen.dir/hashgen.c.o" \
"CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o" \
"CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o" \
"CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o"

# External object files for target hashgen
hashgen_EXTERNAL_OBJECTS = \
"/home/cc/build/blake3_sse2_x86-64_unix.o" \
"/home/cc/build/blake3_sse41_x86-64_unix.o" \
"/home/cc/build/blake3_avx2_x86-64_unix.o" \
"/home/cc/build/blake3_avx512_x86-64_unix.o"

hashgen: CMakeFiles/hashgen.dir/hashgen.c.o
hashgen: CMakeFiles/hashgen.dir/BLAKE3/c/blake3.c.o
hashgen: CMakeFiles/hashgen.dir/BLAKE3/c/blake3_dispatch.c.o
hashgen: CMakeFiles/hashgen.dir/BLAKE3/c/blake3_portable.c.o
hashgen: blake3_sse2_x86-64_unix.o
hashgen: blake3_sse41_x86-64_unix.o
hashgen: blake3_avx2_x86-64_unix.o
hashgen: blake3_avx512_x86-64_unix.o
hashgen: CMakeFiles/hashgen.dir/build.make
hashgen: CMakeFiles/hashgen.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/cc/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_9) "Linking C executable hashgen"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/hashgen.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/hashgen.dir/build: hashgen
.PHONY : CMakeFiles/hashgen.dir/build

CMakeFiles/hashgen.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/hashgen.dir/cmake_clean.cmake
.PHONY : CMakeFiles/hashgen.dir/clean

CMakeFiles/hashgen.dir/depend: blake3_avx2_x86-64_unix.o
CMakeFiles/hashgen.dir/depend: blake3_avx512_x86-64_unix.o
CMakeFiles/hashgen.dir/depend: blake3_sse2_x86-64_unix.o
CMakeFiles/hashgen.dir/depend: blake3_sse41_x86-64_unix.o
	cd /home/cc/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/cc /home/cc /home/cc/build /home/cc/build /home/cc/build/CMakeFiles/hashgen.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/hashgen.dir/depend

