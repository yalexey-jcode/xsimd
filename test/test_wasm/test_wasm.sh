#!/bin/bash
set -e

# this dir
TEST_WASM_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$TEST_WASM_DIR/../..

# the emsdk dir can be passed as optional argument
if [ $# -eq 0 -o ! -d "$1" ]
then
    EMSCRIPTEN_VERSION=${1:-latest}
    # ... (код загрузки emsdk без изменений) ...
    git clone https://github.com/emscripten-core/emsdk
    cd emsdk
    ./emsdk install ${EMSCRIPTEN_VERSION}
    ./emsdk activate ${EMSCRIPTEN_VERSION}
    source ./emsdk_env.sh
else
    EMSCRIPTEN_DIR=$1
    source $EMSCRIPTEN_DIR/emsdk_env.sh
fi

# --- УДАЛЕНО: Очистка переменных (LDFLAGS, CFLAGS, CXXFLAGS) ---
# Теперь скрипт будет уважать флаги, переданные из GitHub Actions

# build wasm
mkdir -p build
cd build

# Добавили "${CMAKE_ARGS}" в конец, чтобы передавать доп. опции если нужно
emcmake cmake \
    -DBUILD_TESTS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DDOWNLOAD_DOCTEST=ON \
    ${CMAKE_ARGS} \
    $SRC_DIR

emmake make -j4
cd ..

# run tests in browser
python $TEST_WASM_DIR/test_wasm_playwright.py  build/test