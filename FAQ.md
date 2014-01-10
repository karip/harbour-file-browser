
# FAQ for File Browser for Sailfish OS 

### What is File Browser?

File Browser is a simple tool to access file system without 
enabling developer mode or registering to Yandex and installing
a file manager from there.

### Why copying files gives an error message 'Failure to write block'?

Your storage (phone or sd card) is most likely full.

### What does error 'Unknown error' mean?

If you tried to move a directory from SD Card to phone or
from phone to SD Card, then you get this error message. Instead of 
moving (cut-paste), you should copy the directory.

### Why opening a file does not work, but gives error "No application to open the file"?

It means that the xdg-open command used to open files does not recognize
the file type or it doesn't find a preferred program to open it.

The Sailfish OS is still at beta stage, so it doesn't have all bindings
for all media formats.

### Why accessing SD Card gives error 'SD Card not found'?

Perhaps your SD Card is not properly inserted to the phone.
Perhaps it has a file system which is not recognized by the phone.
You can also try to access the SD Card with another file manager, 
such as Cargo Dock.

### How can I see how much space is left on phone or SD Card?

Free phone storage space can be seen from phone settings. 
Free space of an SD Card, don't know how to see that.

### Are there any alternative apps?

There is the wonderful Cargo Dock file manager in the Jolla store.
You can also try the Jolla's own file manager called Files,
which can be installed with 'pkcon install jolla-fileman' 
in Terminal (requires Developer Mode).

### Does it have XXX feature?

It can't rename files, change permissions, change owners, 
sudo, go to Android home folder, multi-select files, 
edit files, share files, send email, mms or sms, open ftp sites, 
connect to samba server, simulate vi and it does not blend or make coffee.

