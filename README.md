# File Browser for Sailfish OS

A minimal file browser tool to view files on 
[Sailfish OS](https://sailfishos.org/) and 
[Jolla phones](http://jolla.com/).

There is a [FAQ](https://github.com/karip/harbour-file-browser/blob/master/FAQ.md)
about most common questions.

### Warning

USE AT YOUR OWN RISK. This app can be used to corrupt files on the phone
and make the phone unusable. The author of File Browser does not take any
responsibility if that happens. So, be careful.

### Features

 * Browse and search files and folders on the phone
 * Open files (if xdg-open finds a preferred application)
 * Preview JPEG, PNG and GIF files
 * Play back WAV, MP3, OGG and FLAC audio
 * Install Android APK and Sailfish RPM packages
 * View contents of APK, RPM, ZIP and TAR packages
 * View contents of text and binary files
 * Cut, copy and paste files (move/copy files) (by long pressing an 
   item or tapping the file icon in a list)
 * Rename files and folders
 * Create new folders
 * Delete files and folders (by long pressing an item or tapping 
   its file icon in a list)
 * Show hidden files (filenames starting with a dot)
 * Change permissions

### Acknowledgements

File Browser is based on the excellent 
[Helloworld Pro](https://github.com/amarchen/helloworld-pro-sailfish) 
template.

The Exif data is displayed with [JHead](http://www.sentex.net/~mwandel/jhead/),
which is a public domain Exif manipulation tool.

### Other file managers

There is a very handy two-paned file manager called Cargo Dock
in the Jolla Store. Give it a try if you are moving a lot of files.

OpenRepos has a powerful file manager called
[Filetug](https://openrepos.net/content/matoking/filetug).

The Jolla phone also ships with its own file manager called Files.
It is not installed by default. You can install it by typing the 
following command in Terminal (requires Developer Mode).

    pkcon install jolla-fileman

Android app stores also have file managers, such as ES File Explorer,
which are good when accessing Android storage.

## Building

1. Get the source code
2. Convert translation source files into qm files, run these on command line

        lrelease src/i18n/file-browser_fi.ts -qm src/i18n/file-browser_fi.qm
        lrelease src/i18n/file-browser_de.ts -qm src/i18n/file-browser_de.qm
        lrelease src/i18n/file-browser_zh_CN.ts -qm src/i18n/file-browser_zh_CN.qm

3. Open the harbour-file-browser.pro in Sailfish OS IDE 
   (Qt Creator for Sailfish)
4. To run on emulator, select the i486 target and press the run button
5. To build for the device, select the armv7hl target and deploy all, 
   the rpm packages will be in the RPMS folder

## License

All files in this project have been released into public domain, which 
means that you can do whatever you want with this software. See below 
for details.

***

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>

