// repro for clangd crash from github.com/clangd/clangd issue #1072
#include <exception>
int main() {
    std::exception_ptr foo;
    try {} catch (...) { }
    return 0;
}
