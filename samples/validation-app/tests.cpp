#include "core.h"
#include <iostream>
#include <fstream>
#include <string>

int main() {
    const char* test_file = "test_output.txt";
    const char* test_msg = "WBAB-TEST-SUCCESS";

    std::cout << "Running unit tests..." << std::endl;

    if (!WriteMessage(test_file, test_msg)) {
        std::cerr << "FAILED: WriteMessage returned 0" << std::endl;
        return 1;
    }

    std::ifstream f(test_file);
    std::string line;
    if (!std::getline(f, line)) {
        std::cerr << "FAILED: Could not read from test file" << std::endl;
        return 1;
    }

    if (line != test_msg) {
        std::cerr << "FAILED: Content mismatch. Expected '" << test_msg << "', got '" << line << "'" << std::endl;
        return 1;
    }

    std::cout << "Unit tests PASSED" << std::endl;
    return 0;
}
