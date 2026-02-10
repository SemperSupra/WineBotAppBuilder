cmake_minimum_required(VERSION 3.10)
project(WineBotValidationApp CXX)

set(CMAKE_CXX_STANDARD 17)

# Core DLL
add_library(ValidationCore SHARED core.cpp)
set_target_properties(ValidationCore PROPERTIES PREFIX "") # No 'lib' prefix on Windows

# CLI Tool
add_executable(ValidationCLI cli.cpp)
target_link_libraries(ValidationCLI ValidationCore)

# GUI Tool
# Remove WIN32 to default to console subsystem, ensuring stdout is captured.
# MinGW should still find WinMain as the entry point or we can switch to main if needed.
add_executable(ValidationGUI gui.cpp)
target_link_libraries(ValidationGUI ValidationCore user32 gdi32)
