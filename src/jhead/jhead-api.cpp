//
// This is a modified version of jhead 2.97, which is a
// public domain Exif manipulation tool.
//
// The original files can be found at http://www.sentex.net/~mwandel/jhead/
//
// A good resource for exif tags is
// http://www.awaresystems.be/imaging/tiff/tifftags/privateifd/exif.html

// Functions modified to output to a QStringList instead of stdout

#include <QObject>
#include <sys/stat.h>
#include "jhead-api.h"

int ShowTags     = FALSE;    // Do not show raw by default.
int DumpExifMap  = FALSE;

// dummy printf
int xprintf(const char *, ...) { return 0; }

// not used - only defined to get exif.c to compile
void FileTimeAsString(char * TimeStr)
{
    struct tm ts;
    ts = *localtime(&ImageInfo.FileDateTime);
    strftime(TimeStr, 20, "%Y:%m:%d %H:%M:%S", &ts);
}

// from exif.c
static const char * OrientTab[9] = {
    "Undefined",
    "Normal",           // 1
    "Flip horizontal",  // left right reversed mirror
    "Rotate 180",       // 3
    "Flip vertical",    // upside down mirror
    "Transpose",        // Flipped about top-left <--> bottom-right axis.
    "Rotate 90 CW",        // rotate 90 cw to right it.
    "Transverse",       // flipped about top-right <--> bottom-left axis
    "Rotate 270 CW",       // rotate 270 to right it.
};

typedef struct {
    unsigned short Tag;
    const char * Desc;
}TagTable_t;

// Table of Jpeg encoding process names
static const TagTable_t ProcessTable[] = {
    { M_SOF0,   "Baseline"},
    { M_SOF1,   "Extended sequential"},
    { M_SOF2,   "Progressive"},
    { M_SOF3,   "Lossless"},
    { M_SOF5,   "Differential sequential"},
    { M_SOF6,   "Differential progressive"},
    { M_SOF7,   "Differential lossless"},
    { M_SOF9,   "Extended sequential, arithmetic coding"},
    { M_SOF10,  "Progressive, arithmetic coding"},
    { M_SOF11,  "Lossless, arithmetic coding"},
    { M_SOF13,  "Differential sequential, arithmetic coding"},
    { M_SOF14,  "Differential progressive, arithmetic coding"},
    { M_SOF15,  "Differential lossless, arithmetic coding"},
};

#define PROCESS_TABLE_SIZE  (sizeof(ProcessTable) / sizeof(TagTable_t))

// from iptc.c
// IPTC entry types known to Jhead (there's many more defined)
#define IPTC_RECORD_VERSION         0x00
#define IPTC_SUPLEMENTAL_CATEGORIES 0x14
#define IPTC_KEYWORDS               0x19
#define IPTC_CAPTION                0x78
#define IPTC_AUTHOR                 0x7A
#define IPTC_HEADLINE               0x69
#define IPTC_SPECIAL_INSTRUCTIONS   0x28
#define IPTC_CATEGORY               0x0F
#define IPTC_BYLINE                 0x50
#define IPTC_BYLINE_TITLE           0x55
#define IPTC_CREDIT                 0x6E
#define IPTC_SOURCE                 0x73
#define IPTC_COPYRIGHT_NOTICE       0x74
#define IPTC_OBJECT_NAME            0x05
#define IPTC_CITY                   0x5A
#define IPTC_STATE                  0x5F
#define IPTC_COUNTRY                0x65
#define IPTC_TRANSMISSION_REFERENCE 0x67
#define IPTC_DATE                   0x37
#define IPTC_COPYRIGHT              0x0A
#define IPTC_COUNTRY_CODE           0x64
#define IPTC_REFERENCE_SERVICE      0x2D
#define IPTC_TIME_CREATED           0x3C
#define IPTC_SUB_LOCATION           0x5C
#define IPTC_IMAGE_TYPE             0x82




// called from other files
void ErrFatal(const char * msg)
{
    Q_UNUSED(msg);
    return;
}

void ErrNonfatal(const char * msg, int a1, int a2)
{
    Q_UNUSED(msg);
    Q_UNUSED(a1);
    Q_UNUSED(a2);
    return;
}

//--------------------------------------------------------------------------
// Show the collected image info, displaying camera F-stop and shutter speed
// in a consistent and legible fashion.
//--------------------------------------------------------------------------
void appendImageInfo(QStringList &metadata)
{
    if (ImageInfo.CameraMake[0]){
        metadata.append(QObject::tr("Make:%1").arg(QString::fromUtf8(ImageInfo.CameraMake)));
        metadata.append(QObject::tr("Model:%1").arg(QString::fromUtf8(ImageInfo.CameraModel)));
    }
    if (ImageInfo.DateTime[0]){
        metadata.append(QObject::tr("Date/Time:%1").arg(QString::fromUtf8(ImageInfo.DateTime)));
    }

//    metadata.append(QObject::tr("Resolution:%1 x %2").arg(ImageInfo.Width).arg(ImageInfo.Height));

    if (ImageInfo.Orientation > 1){
        // Only print orientation if one was supplied, and if its not 1 (normal orientation)
        metadata.append(QObject::tr("Orientation:%1")
                        .arg(QString::fromUtf8(OrientTab[ImageInfo.Orientation])));
    }

    if (ImageInfo.IsColor == 0){
        metadata.append(QObject::tr("Color/BW:Black and White"));
    }

    if (ImageInfo.FlashUsed >= 0){
        if (ImageInfo.FlashUsed & 1){
            QString flash;
            switch (ImageInfo.FlashUsed){
                case 0x5: flash = QObject::tr("(Strobe light not detected)"); break;
                case 0x7: flash = QObject::tr("(Strobe light detected) "); break;
                case 0x9: flash = QObject::tr("(Manual)"); break;
                case 0xd: flash = QObject::tr("(Manual, return light not detected)"); break;
                case 0xf: flash = QObject::tr("(Manual, return light detected)"); break;
                case 0x19:flash = QObject::tr("(Auto)"); break;
                case 0x1d:flash = QObject::tr("(Auto, return light not detected)"); break;
                case 0x1f:flash = QObject::tr("(Auto, return light detected)"); break;
                case 0x41:flash = QObject::tr("(Red eye reduction mode)"); break;
                case 0x45:flash = QObject::tr("(Red eye reduction mode return light not detected)"); break;
                case 0x47:flash = QObject::tr("(Red eye reduction mode return light detected)"); break;
                case 0x49:flash = QObject::tr("(Manual, red eye reduction mode)"); break;
                case 0x4d:flash = QObject::tr("(Manual, red eye reduction mode, return light not detected)"); break;
                case 0x4f:flash = QObject::tr("(Red eye reduction mode, return light detected)"); break;
                case 0x59:flash = QObject::tr("(Auto, red eye reduction mode)"); break;
                case 0x5d:flash = QObject::tr("(Auto, red eye reduction mode, return light not detected)"); break;
                case 0x5f:flash = QObject::tr("(Auto, red eye reduction mode, return light detected)"); break;
            }
            metadata.append(QObject::tr("Flash:Yes")+" "+flash);

        }else{
            QString flash;
            switch (ImageInfo.FlashUsed){
                case 0x18:flash = QObject::tr("(Auto)"); break;
            }
            metadata.append(QObject::tr("Flash:No")+" "+flash);
        }
    }


    if (ImageInfo.FocalLength){
        QString fl = QObject::tr("Focal Length:%1mm").arg((double)ImageInfo.FocalLength, 3, 'f', 1);
        if (ImageInfo.FocalLength35mmEquiv){
            fl = fl + " " + QObject::tr("(35mm equivalent: %1mm)").arg(ImageInfo.FocalLength35mmEquiv);
        }
        metadata.append(fl);
    }

    if (ImageInfo.DigitalZoomRatio > 1){
        // Digital zoom used.  Shame on you!
        metadata.append(QObject::tr("Digital Zoom:%1x").arg((double)ImageInfo.DigitalZoomRatio, 1, 'f', 3));
    }

    if (ImageInfo.CCDWidth){
        metadata.append(QObject::tr("CCD Width:%1").arg((double)ImageInfo.CCDWidth, 3, 'f', 2));
    }

    if (ImageInfo.ExposureTime){
        QString et;
        if (ImageInfo.ExposureTime < 0.010){
            et = QObject::tr("Exposure Time:%1").arg((double)ImageInfo.ExposureTime, 6, 'f', 4);
        }else{
            et = QObject::tr("Exposure Time:%1").arg((double)ImageInfo.ExposureTime, 5, 'f', 3);
        }
        if (ImageInfo.ExposureTime <= 0.5){
            et = et + " " + QObject::tr("(1/%1)").arg((int)(0.5 + 1/ImageInfo.ExposureTime));
        }
        metadata.append(et);
    }
    if (ImageInfo.ApertureFNumber){
        metadata.append(QObject::tr("Aperture:f/%1").arg((double)ImageInfo.ApertureFNumber, 3, 'f', 1));
    }
    if (ImageInfo.Distance){
        if (ImageInfo.Distance < 0){
            metadata.append(QObject::tr("Focus Distance:Infinite"));
        }else{
            metadata.append(QObject::tr("Focus Distance:%1m").arg((double)ImageInfo.Distance, 4, 'f', 2));
        }
    }

    if (ImageInfo.ISOequivalent){
        metadata.append(QObject::tr("ISO Equivalent:%1").arg((int)ImageInfo.ISOequivalent));
    }

    if (ImageInfo.ExposureBias){
        // If exposure bias was specified, but set to zero, presumably its no bias at all,
        // so only show it if its nonzero.
        metadata.append(QObject::tr("Exposure Bias:%1").arg((double)ImageInfo.ExposureBias, 4, 'f', 2));
    }

    switch(ImageInfo.Whitebalance) {
        case 1:
            metadata.append(QObject::tr("White Balance:Manual"));
            break;
        case 0:
            metadata.append(QObject::tr("White Balance:Auto"));
            break;
    }

    //Quercus: 17-1-2004 Added LightSource, some cams return this, whitebalance or both
    switch(ImageInfo.LightSource) {
        case 1:
            metadata.append(QObject::tr("Light Source:Daylight"));
            break;
        case 2:
            metadata.append(QObject::tr("Light Source:Fluorescent"));
            break;
        case 3:
            metadata.append(QObject::tr("Light Source:Incandescent"));
            break;
        case 4:
            metadata.append(QObject::tr("Light Source:Flash"));
            break;
        case 9:
            metadata.append(QObject::tr("Light Source:Fine weather"));
            break;
        case 11:
            metadata.append(QObject::tr("Light Source:Shade"));
            break;
        default:; //Quercus: 17-1-2004 There are many more modes for this, check Exif2.2 specs
            // If it just says 'unknown' or we don't know it, then
            // don't bother showing it - it doesn't add any useful information.
    }

    if (ImageInfo.MeteringMode > 0){ // 05-jan-2001 vcs
        QString m = QObject::tr("Metering Mode:");
        switch(ImageInfo.MeteringMode) {
        case 1: m += QObject::tr("Average"); break;
        case 2: m += QObject::tr("Center weighted average"); break;
        case 3: m += QObject::tr("Spot"); break;
        case 4: m += QObject::tr("Multi spot"); break;
        case 5: m += QObject::tr("Pattern"); break;
        case 6: m += QObject::tr("Partial"); break;
        case 255: m += QObject::tr("Other"); break;
        default: m += QObject::tr("Unknown (%1)").arg(ImageInfo.MeteringMode); break;
        }
        metadata.append(m);
    }

    if (ImageInfo.ExposureProgram){ // 05-jan-2001 vcs
        QString e = QObject::tr("Exposure Program:");
        switch(ImageInfo.ExposureProgram) {
        case 1:
            e += QObject::tr("Manual");
            break;
        case 2:
            e += QObject::tr("Program (auto)");
            break;
        case 3:
            e += QObject::tr("Aperture priority (semi-auto)");
            break;
        case 4:
            e += QObject::tr("Shutter priority (semi-auto)");
            break;
        case 5:
            e += QObject::tr("Creative Program (based towards depth of field)");
            break;
        case 6:
            e += QObject::tr("Action program (based towards fast shutter speed)");
            break;
        case 7:
            e += QObject::tr("Portrait mode");
            break;
        case 8:
            e += QObject::tr("Landscape mode");
            break;
        default:
            break;
        }
        metadata.append(e);
    }
    switch(ImageInfo.ExposureMode){
        case 0: // Automatic (not worth cluttering up output for)
            break;
        case 1: metadata.append(QObject::tr("Exposure Mode:Manual"));
            break;
        case 2: metadata.append(QObject::tr("Exposure Mode:Auto bracketing"));
            break;
    }

    if (ImageInfo.DistanceRange) {
        QString fr = QObject::tr("Focus Range:");
        switch(ImageInfo.DistanceRange) {
            case 1:
                fr += QObject::tr("Macro");
                break;
            case 2:
                fr += QObject::tr("Close");
                break;
            case 3:
                fr += QObject::tr("Distant");
                break;
        }
        metadata.append(fr);
    }



    if (ImageInfo.Process != M_SOF0){
        // don't show it if its the plain old boring 'baseline' process, but do
        // show it if its something else, like 'progressive' (used on web sometimes)
        unsigned a;
        for (a=0;;a++){
            if (a >= PROCESS_TABLE_SIZE){
                // ran off the end of the table.
                metadata.append(QObject::tr("JPEG Process:Unknown"));
                break;
            }
            if (ProcessTable[a].Tag == ImageInfo.Process){
                metadata.append(QObject::tr("JPEG Process:%1").arg(QString::fromUtf8(ProcessTable[a].Desc)));
                break;
            }
        }
    }

    if (ImageInfo.GpsInfoPresent){
        metadata.append(QObject::tr("Latitude:%1").arg(QString::fromUtf8(ImageInfo.GpsLat)));
        metadata.append(QObject::tr("Longitude:%1").arg(QString::fromUtf8(ImageInfo.GpsLong)));
        if (ImageInfo.GpsAlt[0]) {
            metadata.append(QObject::tr("Altitude:%1").arg(QString::fromUtf8(ImageInfo.GpsAlt)));
        }

    }

    if (ImageInfo.QualityGuess){
        metadata.append(QObject::tr("JPEG Quality:%1").arg(ImageInfo.QualityGuess));
    }

    // Print the comment. Print 'Comment:' for each new line of comment.
    if (ImageInfo.Comments[0]){
        int a,c;
        QString comment = QObject::tr("Comment:");
        QByteArray rawComment;
        if (!ImageInfo.CommentWidthchars){
            for (a=0;a<MAX_COMMENT_SIZE;a++){
                c = ImageInfo.Comments[a];
                if (c == '\0') break;
                if (c == '\n'){
                    // Do not start a new line if the string ends with a carriage return.
                    if (ImageInfo.Comments[a+1] != '\0'){
                        comment += QString::fromUtf8(rawComment);
                        metadata.append(comment);
                        comment = QObject::tr("Comment:");
                    }else{
                        comment += "\n";
                    }
                }else{
                    rawComment.append(c);
                    putchar(c);
                }
            }
            comment += QString::fromUtf8(rawComment);
            metadata.append(comment);
        }else{
            comment += QString::fromUtf16((ushort *)ImageInfo.Comments, ImageInfo.CommentWidthchars);
            metadata.append(comment);
        }
    }
}

void appendIPTC(unsigned char* Data, unsigned int itemlen, QStringList &metadata)
{
    const char IptcSig1[] = "Photoshop 3.0";
    const char IptcSig2[] = "8BIM";
    const char IptcSig3[] = {0x04, 0x04};

    unsigned char * pos    = Data + sizeof(short);   // position data pointer after length field
    unsigned char * maxpos = Data+itemlen;
    unsigned char headerLen = 0;
    unsigned char dataLen = 0;

    if (itemlen < 25) goto corrupt;

    // Check IPTC signatures
    if (memcmp(pos, IptcSig1, sizeof(IptcSig1)-1) != 0) goto badsig;
    pos += sizeof(IptcSig1);      // move data pointer to the next field

    if (memcmp(pos, IptcSig2, sizeof(IptcSig2)-1) != 0) goto badsig;
    pos += sizeof(IptcSig2)-1;          // move data pointer to the next field


    while (memcmp(pos, IptcSig3, sizeof(IptcSig3)) != 0) { // loop on valid Photoshop blocks

        pos += sizeof(IptcSig3); // move data pointer to the Header Length
        // Skip header
        headerLen = *pos; // get header length and move data pointer to the next field
        pos += (headerLen & 0xfe) + 2; // move data pointer to the next field (Header is padded to even length, counting the length byte)

        pos += 3; // move data pointer to length, assume only one byte, TODO: use all 4 bytes

        dataLen = *pos++;
        pos += dataLen; // skip data section

        if (memcmp(pos, IptcSig2, sizeof(IptcSig2) - 1) != 0) {
            badsig: if (ShowTags) {
                ErrNonfatal("IPTC type signature mismatch\n", 0, 0);
            }
            return;
        }
        pos += sizeof(IptcSig2) - 1; // move data pointer to the next field
    }

    pos += sizeof(IptcSig3);          // move data pointer to the next field

    if (pos >= maxpos) goto corrupt;

    // IPTC section found

    // Skip header
    headerLen = *pos++;                     // get header length and move data pointer to the next field
    pos += headerLen + 1 - (headerLen % 2); // move data pointer to the next field (Header is padded to even length, counting the length byte)

    if (pos+4 >= maxpos) goto corrupt;

    // Get length (from motorola format)
    //length = (*pos << 24) | (*(pos+1) << 16) | (*(pos+2) << 8) | *(pos+3);

    pos += 4;                    // move data pointer to the next field

    //printf("======= IPTC data: =======\n");

    // Now read IPTC data
    while (pos < (Data + itemlen-5)) {
        short  signature;
        unsigned char   type = 0;
        short  length = 0;
        QString description;

        if (pos+5 > maxpos) goto corrupt;

        signature = (*pos << 8) + (*(pos+1));
        pos += 2;

        if (signature != 0x1C01 && signature != 0x1c02) break;

        type    = *pos++;
        length  = (*pos << 8) + (*(pos+1));
        pos    += 2;                          // Skip tag length

        if (pos+length > maxpos) goto corrupt;
        // Process tag here
        switch (type) {
            case IPTC_RECORD_VERSION:
                // always 4, so irrelevant information
                //metadata.append(QObject::tr("Record Version:%1").arg((int)((*pos << 8) + (*(pos+1)))));
                break;

            case IPTC_SUPLEMENTAL_CATEGORIES:  description = "Suplemental Categories"; break;
            case IPTC_KEYWORDS:                description = "Keywords"; break;
            case IPTC_CAPTION:                 description = "Caption"; break;
            case IPTC_AUTHOR:                  description = "Author"; break;
            case IPTC_HEADLINE:                description = "Headline"; break;
            case IPTC_SPECIAL_INSTRUCTIONS:    description = "Special Instructions"; break;
            case IPTC_CATEGORY:                description = "Category"; break;
            case IPTC_BYLINE:                  description = "Byline"; break;
            case IPTC_BYLINE_TITLE:            description = "Byline Title"; break;
            case IPTC_CREDIT:                  description = "Credit"; break;
            case IPTC_SOURCE:                  description = "Source"; break;
            case IPTC_COPYRIGHT_NOTICE:        description = "Copyright Notice"; break;
            case IPTC_OBJECT_NAME:             description = "Object Name"; break;
            case IPTC_CITY:                    description = "City"; break;
            case IPTC_STATE:                   description = "State"; break;
            case IPTC_COUNTRY:                 description = "Country"; break;
            case IPTC_TRANSMISSION_REFERENCE:  description = "Original Transmission Reference"; break;
            case IPTC_DATE:                    description = "Date Created"; break;
            case IPTC_COPYRIGHT:               description = "Urgency"; break;
            case IPTC_REFERENCE_SERVICE:       description = "Reference Service"; break;
            case IPTC_COUNTRY_CODE:            description = "Country Code"; break;
            case IPTC_TIME_CREATED:            description = "Time Created"; break;
            case IPTC_SUB_LOCATION:            description = "Sub Location"; break;
            case IPTC_IMAGE_TYPE:              description = "Image Type"; break;

            default:
                if (ShowTags){
                    //printf("Unrecognised IPTC tag: %d\n", type );
                }
            break;
        }
        // display only applications records (02), not envelope records (01)
        if (!description.isEmpty() && signature == 0x1c02) {
            metadata.append(description+":"+QString::fromUtf8((char *)pos, length));
        }
        pos += length;
    }
    return;
corrupt:
    ErrNonfatal("Pointer corruption in IPTC\n",0,0);
}

// copied from jhead.c ProcessFile()
QStringList jhead_readJpegFile(const char *FileName, bool *error)
{
    QStringList metadata;
    *error = false;


    ReadMode_t ReadMode;

    if (strlen(FileName) >= PATH_MAX-1){
        // Protect against buffer overruns in strcpy / strcat's on filename
        *error = true;
        return metadata;
    }

    ReadMode = READ_METADATA;

    ResetJpgfile();

    // Start with an empty image information structure.
    memset(&ImageInfo, 0, sizeof(ImageInfo));
    ImageInfo.FlashUsed = -1;
    ImageInfo.MeteringMode = -1;
    ImageInfo.Whitebalance = -1;

    // Store file date/time.
    {
        struct stat st;
        if (stat(FileName, &st) >= 0){
            ImageInfo.FileDateTime = st.st_mtime;
            ImageInfo.FileSize = st.st_size;
        }else{
            // file not found
            *error = true;
            return metadata;
        }
    }

    strncpy(ImageInfo.FileName, FileName, PATH_MAX);

    if (!ReadJpegFile(FileName, ReadMode)) return metadata;

    appendImageInfo(metadata);

    {
        // if IPTC section is present, show it also.
        Section_t * IptcSection;
        IptcSection = FindSection(M_IPTC);

        if (IptcSection){
            appendIPTC(IptcSection->Data, IptcSection->Size, metadata);
        }
    }

    DiscardData();
    return metadata;
}
