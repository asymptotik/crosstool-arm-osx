# Raspberry Pi Cross Compiler Script for OSX

Author: Rick Boykin

  Installs a gcc cross compiler for compiling code for raspberry pi on OSX.
  This script is based on several scripts and forum posts I've found around
  the web, the most significant being: 

  http://okertanov.github.com/2012/12/24/osx-crosstool-ng/

  http://crosstool-ng.org/hg/crosstool-ng/file/715b711da3ab/docs/MacOS-X.txt

  http://gnuarmeclipse.livius.net/wiki/Toolchain_installation_on_OS_X

  http://elinux.org/RPi_Kernel_Compilation

  The script downloads, compiles and installs all necessary software. The only prerequisite I know of is to have the latest version of XCode and have the command line tools installed. It works for me without modification on OSX 10.7.4 with XCode 4.5.2

  To use, open and read the build.sh script to suite your needs. Then run the script:

     bash build.sh 

  From within the folder it is contained. It will need the arm-unknown-linux-gnueabi.config file. 

  The code will install some HomeBrew packages. I use mack ports, at which at some time during my attempts to setup this cross compiler it interfered with the install and as such I have it setup to install HomeBrew packages /brew/local such that you don't have to be a normal HomeBrew user and the environment is completely controlled.

  Once HomeBrew is installed, the script creates a sparse HFSX (case sensitive) filesystem on which to perform the build. The filesystem image is a file that lives in the same directory as the script. It is currently set to be created at 8gig. Please be sure to have that much space available. 

  Then the script then downlaods and installs crosstool-ng. It helps to be a little familiar with the tool. See http://crosstool-ng.org/ 

  Once crosstool is installed, it is configured with the arm-unknown-linux-gnueabi.config file by copying that file to the approproite location where crosstool will pick it up. The script then automatically fires up the crosstool config menu (menuconfig) so you can make changes. The menuconfig program is basically a front end for the config file. You can either make changes or just exit. You can also just edit the config file before running the script and remove call to:

       PATH=$BrewHome/bin:$PATH ../${CrossToolVersion}/ct-ng menuconfig

  Once that is all done, we run the build. If all goes well, you will then have a toolchain for comiling arm code on osx. The default install is in /Volumes/CrossToolNG/install/arm-unknown-linux-gnueabi

  As a smoke test you can create a simple HelloWorld program and compile it. That would be something like:

```bash
cat <<EOF >> HelloWorld.cpp
#include <iostream>
using namespace std;

int main ()
{
  cout << "Hello World!";
  return 0;
}
EOF

PATH=/Volumes/CrossToolNG/install/arm-unknown-linux-gnueabi/bin:$PATH arm-linux-gnueabihf-g++ HelloWorld.cpp -o HelloWorld
```

Go forth and compile.