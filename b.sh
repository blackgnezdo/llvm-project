ulimit -d $((20<<20))

cmake -S llvm -B build -G Ninja -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Debug -DOPENBSD_LD_IS_LLD=TRUE

cmake --build build

./build/bin/clang  -O -mllvm -debug-only=aarch64-ldst-opt  --target=arm64 -c  -o /tmp/a.o /usr/src/games/worm/worm.c
