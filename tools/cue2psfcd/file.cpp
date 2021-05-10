// GNU General Public License v2.0
// https://github.com/JaCzekanski/Avocado
#include "file.h"
#include <fstream>
#include <iostream>
#include <sstream> //std::stringstream

std::string getPath(const std::string& name) {
    size_t begin = 0, end = name.length();

    size_t slash = name.find_last_of("/\\");
    if (slash != std::string::npos) end = slash + 1;

    return name.substr(begin, end - begin);
}

std::string getFilenameExt(const std::string& name) {
    size_t begin = 0, end = name.length();

    size_t slash = name.find_last_of("/\\");
    if (slash != std::string::npos) begin = slash + 1;

    return name.substr(begin, end);
}

std::string getFilename(const std::string& name) {
    size_t begin = 0, end = name.length();

    size_t slash = name.find_last_of("/\\");
    if (slash != std::string::npos) begin = slash + 1;

    size_t dot = name.find_last_of('.');
    if (dot != std::string::npos) end = dot;

    return name.substr(begin, end - begin);
}

std::string getExtension(const std::string& name) {
    size_t found = name.find_last_of('.');
    if (found == std::string::npos) return "";
    return name.substr(found + 1);
}


size_t getFileSize(const std::string &name) {
    long size = -1;

    FILE *f = fopen(name.c_str(), "rb");
    if (f)
    {
        fseek(f, 0, SEEK_END);
        size = ftell(f);
        fclose(f);
    }

    return size;
}

std::string getFileContentsAsString(const std::string &name)
{
    std::ifstream ifs(name);
    return std::string((std::istreambuf_iterator<char>(ifs)),
                  (std::istreambuf_iterator<char>()));
}