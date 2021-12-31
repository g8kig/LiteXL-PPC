#!/bin/bash
set -e

cflags="-Wall -O2 -g -std=gnu11 -fno-strict-aliasing -Isrc -faltivec"
lflags="-lm"

platform="macosx"
outfile="lite-xl"
compiler="gcc-6"
cflags="$cflags `osxlib/SDL2-2.0.6/sdl2-config --cflags` `/usr/local/Cellar/pcre2/10.39/bin/pcre2-config --cflags` `/usr/local/Cellar/freetype/2.11.1/bin/freetype-config --cflags` -Iosxlib/SDL2-2.0.6/include -DLUA_USE_POSIX"
lflags="$lflags `osxlib/SDL2-2.0.6/sdl2-config --libs`   `/usr/local/Cellar/pcre2/10.39/bin/pcre2-config --libs8`  `/usr/local/Cellar/freetype/2.11.1/bin/freetype-config --libs` -o $outfile"

if command -v ccache >/dev/null; then
  compiler="ccache $compiler"
fi

echo "compiling ($platform)..."
for f in `find src -name "*.c"`; do
  $compiler -c $cflags $f -o "${f//\//_}.o"
  if [[ $? -ne 0 ]]; then
    got_error=true
  fi
done

if [[ ! $got_error ]]; then
  echo "linking..."
  $compiler *.o $lflags
fi

echo "cleaning up..."
rm *.o
rm res.res 2>/dev/null

echo "patching dylibs..."
cp ./lite-xl 						  "./Lite XL.app/Contents/MacOS" 
cp ./osxlib/SDL2-2.0.6/libs/libSDL2-2.0.0.dylib \
									  "./Lite XL.app/Contents/MacOS"
rm -f "./Lite XL.app/Contents/MacOS/libpcre2-8.0.dylib"
rm -f "./Lite XL.app/Contents/MacOS/libfreetype.6.dylib"
cp /usr/local/lib/libpcre2-8.0.dylib  "./Lite XL.app/Contents/MacOS"
cp /usr/local/lib/libfreetype.6.dylib "./Lite XL.app/Contents/MacOS"

install_name_tool -change /usr/local/lib/libSDL2-2.0.0.dylib @executable_path/libSDL2-2.0.0.dylib "Lite XL.app/Contents/MacOS/lite-xl"
install_name_tool -change /usr/local/lib/libpcre2-8.0.dylib  @executable_path/libpcre2-8.0.dylib  "Lite XL.app/Contents/MacOS/lite-xl"
install_name_tool -change /usr/local/lib/libfreetype.6.dylib @executable_path/libfreetype.6.dylib "Lite XL.app/Contents/MacOS/lite-xl"
otool -L "Lite XL.app/Contents/MacOS/lite-xl"

echo "done"
