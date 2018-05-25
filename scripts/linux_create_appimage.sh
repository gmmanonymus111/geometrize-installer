#!/bin/bash

echo Will create AppImage

# Download linuxdeployqt
wget -c "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage" -O linuxdeployqt
chmod a+x linuxdeployqt

unset QTDIR; unset QT_PLUGIN_PATH; unset LD_LIBRARY_PATH

yes | cp Geometrize appdir/geometrize

# Run linuxdeployqt
./linuxdeployqt appdir/geometrize -bundle-non-qt-libs -verbose=2

# Extract the base appimage
./linuxdeployqt --appimage-extract

mkdir -p appdir/usr/

# Workarounds so the AppImage runs on systems that ship old gcc (and so older libstdc++/libgcc)
# like Ubuntu 14.04 (see https://github.com/Tw1ddle/geometrize/issues/5)
# Assumes g++-8 and libstdc++-8-dev were installed and used to build the app
ls -a /usr/lib/x86_64-linux-gnu/

mkdir -p appdir/usr/optional/
mkdir -p appdir/usr/optional/libstdc++/

cp /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 ./appdir/usr/optional/libgcc_s/
cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25 ./appdir/usr/optional/libstdc++/libstdc++.so.6

wget -c "https://github.com/darealshinji/AppImageKit-checkrt/releases/download/continuous/exec-x86_64.so" -O ./appdir/usr/optional/exec.so
# Replace AppRun with the patched one
pushd appdir
rm AppRun
wget -c "https://github.com/darealshinji/AppImageKit-checkrt/releases/download/continuous/AppRun-patched-x86_64" -O AppRun
chmod a+x AppRun
popd

# Pack everything back into an AppImage
export PATH=$(readlink -f ./squashfs-root/):$PATH
NAME=$(grep '^Name=.*' appdir/geometrize.desktop | cut -d "=" -f 2 | sed -e 's|\ |_|g')
./squashfs-root/usr/bin/appimagetool -g ./appdir/ Geometrize.AppImage