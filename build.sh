#!/bin/bash
#
#  Author: Rick Boykin
#
#  Installs a gcc cross compiler for compiling code for raspberry pi on OSX.
#  This script is based on several scripts and forum posts I've found around
#  the web, the most significant being: 
#
#  http://okertanov.github.com/2012/12/24/osx-crosstool-ng/
#  http://crosstool-ng.org/hg/crosstool-ng/file/715b711da3ab/docs/MacOS-X.txt
#  http://gnuarmeclipse.livius.net/wiki/Toolchain_installation_on_OS_X
#  http://elinux.org/RPi_Kernel_Compilation
#
#
#  And serveral articles that mostly dealt with the MentorGraphics tool, which I
#  I abandoned in favor of crosstool-ng
#
#  The process:
#      Install HomeBrew and packages: gnu-sed binutils gawk automake libtool bash and grep
#      Homebrew is installed in $GrewHome so as not to interfere with macports or fink
#
#      Create case sensitive volume using hdiutil and mount it to /Volumes/$ImageName
#
#      Download, patch and build crosstool-ng
#
#      Configure and build the toolchain.
#
#  License:
#      Please feel free to use this in any way you see fit.
#
set -e -u

#
# Config. Update here to suite your specific needs. I've
#
InstallBase=`pwd`
BrewHome=/brew2/local
BrewTools="gnu-sed binutils gawk automake libtool bash"
BrewToolsExtra="https://raw.github.com/Homebrew/homebrew-dupes/master/grep.rb"
ImageName=CrossTool2NG
ImageNameExt=${ImageName}.sparseimage
CrossToolVersion=crosstool-ng-1.17.0
ToolChainName=arm-unknown-linux-gnueabi

#
# If $BrewHome does not alread contain HomeBrew, download and install it. 
# Install the required HomeBrew packages.
#
function buildBrewDepends()
{
    if [ ! -d "$BrewHome" ]
    then
      echo "If asked, enter your sudo password to create the $BrewHome folder"
      sudo mkdir -p "$BrewHome"
      sudo chown -R $USER "$BrewHome"
      curl -Lsf http://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C$BrewHome
    fi
    echo "Updating HomeBrew tools..."
    $BrewHome/bin/brew update
    $BrewHome/bin/brew upgrade
    set +e
    $BrewHome/bin/brew install $BrewTools && true
    $BrewHome/bin/brew install $BrewToolsExtra && true
    set -e
}

function createCaseSensitiveVolume()
{
    echo "Creating sparse volume mounted on /Volumes/${ImageName}..."
    ImageNameExt=${ImageName}.sparseimage
    diskutil umount force /Volumes/${ImageName} && true
    rm -f ${ImageNameExt} && true
    hdiutil create ${ImageName} -volname ${ImageName} -type SPARSE -size 8g -fs HFSX
    hdiutil mount ${ImageNameExt}
}

function downloadCrossTool()
{
    cd /Volumes/$ImageName
    echo "Downloading crosstool-ng..."
    CrossToolArchive=${CrossToolVersion}.tar.bz2
    CrossToolUrl=http://crosstool-ng.org/download/crosstool-ng/${CrossToolArchive}
    curl -L -o ${CrossToolArchive} $CrossToolUrl
    tar xvf $CrossToolArchive
    #rm -f $CrossToolArchive
}

function patchCrosstool()
{
    cd /Volumes/$ImageName/$CrossToolVersion
    echo "Patching crosstool-ng..."
    sed -i .bak '6i\
#include <stddef.h>' kconfig/zconf.y
}

function buildCrosstool()
{
    echo "Configuring crosstool-ng..."
    ./configure --enable-local \
	--with-objcopy=$BrewHome/bin/gobjcopyi       \
	--with-objdump=$BrewHome/bin/gobjdump        \
	--with-ranlib=$BrewHome/bin/granlib          \
	--with-readelf=$BrewHome/bin/greadelf        \
	--with-libtool=$BrewHome/bin/glibtool        \
	--with-libtoolize=$BrewHome/bin/glibtoolize  \
	--with-sed=$BrewHome/bin/gsed                \
	--with-awk=$BrewHome/bin/gawk                \
	--with-automake=$BrewHome/bin/automake       \
	--with-bash=$BrewHome/bin/bash               \
	CFLAGS="-std=c99 -Doffsetof=__builtin_offsetof"
    make
}

function createToolchain()
{
    echo "Creating ARM toolchain $ToolChainName..."
    cd /Volumes/$ImageName
    mkdir $ToolChainName
    cd $ToolChainName

    # the process seems to opena a lot of files at once. The default is 256. Bump it to 1024.
    ulimit -n 1024

    echo "Selecting arm-unknown-linux-gnueabi toolchain..."
    PATH=$BrewHome/bin:$PATH ../${CrossToolVersion}/ct-ng $ToolChainName

    echo "Cleaning toolchain..."
    PATH=$BrewHome/bin:$PATH ../${CrossToolVersion}/ct-ng clean

    echo "Copying my working toolchain configuration"
    cp $InstallBase/${ToolChainName}.config ./.config

    echo "Manually Configuring toolchain"
    echo "        Select 'Force unwind support'"
    echo "        Unselect 'Link libstdc++ statically onto the gcc binary'"
    echo "        Unselect 'Debugging -> dmalloc or fix its build'"

    # Use 'menuconfig' target for the fine tuning.
    PATH=$BrewHome/bin:$PATH ../${CrossToolVersion}/ct-ng menuconfig
}

function buildToolchain()
{
    cd /Volumes/$ImageName/$ToolChainName
    echo "Building toolchain..."
    PATH=$BrewHome/bin:$PATH ../${CrossToolVersion}/ct-ng build.4
    echo "And if all went well, you are done! Go forth and compile."
}

buildBrewDepends
createCaseSensitiveVolume
downloadCrossTool
patchCrosstool
buildCrosstool
createToolchain
buildToolchain
