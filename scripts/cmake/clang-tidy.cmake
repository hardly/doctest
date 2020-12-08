option(ENABLE_CLANG_TIDY "Add clang-tidy checks automatically as prebuild step" OFF)

find_program(CLANG_TIDY_EXE
        NAMES clang-tidy clang-tidy-7
        DOC "Path to clang-tidy executable")
find_program(CLANG_TIDY_RUNNER
        NAMES run-clang-tidy run-clang-tidy-7 run-clang-tidy.py
        HINTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts)
if(CLANG_TIDY_EXE)
    message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
    set(DCMAKE_EXPORT_COMPILE_COMMANDS ON)
    set(CLANG_TIDY_CMD ${CLANG_TIDY_EXE})
    message(STATUS "cmake source dir: ${CMAKE_CURRENT_SOURCE_DIR}")
    # recomment out-of-source build
    if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
        message(AUTHOR_WARNING "In-source build is not recommented!")
    else()
        # NOTE: copy project config file .clang-tidy for later use
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy ${CMAKE_CURRENT_BINARY_DIR} @ONLY)
    endif()

    if(ENABLE_CLANG_TIDY)
        # NOTE: the project config file .clang-tidy is not found if the
        # binary tree is not part of the source tree!
        set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY_CMD} CACHE STRING "" FORCE)
    else()
        set(CMAKE_CXX_CLANG_TIDY "" CACHE STRING "" FORCE) # delete it
    endif()

    if(CLANG_TIDY_RUNNER)
        if(NOT TARGET check)
            add_custom_target(check)
            message(STATUS "check target added")
            # TBD: set_target_properties(check PROPERTIES EXCLUDE_FROM_ALL TRUE)
        endif()

        add_custom_command(TARGET check PRE_BUILD
            # -p BUILD_PATH Path used to read a compile command database (compile_commands.json).
            # NOTE: we use default checks from .clang-tidy and we check src tree only yet!
            COMMAND ${CLANG_TIDY_RUNNER} -p ${CMAKE_CURRENT_BINARY_DIR} examples
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}   # location of compile_commands.json
            COMMENT "Running check on targets at ${CMAKE_CURRENT_SOURCE_DIR} ..."
            VERBATIM
        )
    endif()
else()
    message(AUTHOR_WARNING "clang-tidy not found!")
endif()
