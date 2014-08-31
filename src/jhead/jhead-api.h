//
// This is a modified version of jhead 2.97, which is a
// public domain Exif manipulation tool.
//
// The original files can be found at http://www.sentex.net/~mwandel/jhead/
//


//--------------------------------------------------------------------------
// Include file for jhead program.
//
// This include file only defines stuff that goes across modules.  
// I like to keep the definitions for macros and structures as close to 
// where they get used as possible, so include files only get stuff that 
// gets used in more than one file.
//--------------------------------------------------------------------------
#include <QStringList>

#ifdef __cplusplus
extern "C" {
#endif

#include "jhead.h"

#ifdef __cplusplus
}
#endif

void showImageInfo(QStringList &metadata);

QStringList jhead_readJpegFile(const char *FileName, bool *error);
