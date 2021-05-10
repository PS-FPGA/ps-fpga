#ifndef __PSF_TOC_H__
#define __PSF_TOC_H__

#include <stdint.h>

#define MAXTRACK    100
#define CD_SECT_SZ  2352

enum PSFTrackType { TRACK_TYPE_UNKNOWN, TRACK_TYPE_AUDIO, TRACK_TYPE_DATA };

typedef struct u24_ {
    uint8_t mm;
    uint8_t ss;
    uint8_t ff;
} u24;

struct PSFTrack {
    uint32_t offset;                   // Byte offset
    u24    start;
    u24    size;                       // size of the track in sectors, including pregaps and postgaps
    u24    indices[2];                 // each index is an absolute value in sectors from the beginning
    u24    postgap;                    // size of the postgap in sectors
    int8_t indexCount;
    int8_t trackType;
};

struct PSFDisc {
    uint32_t diskSize;
    int8_t trackCount;
    struct PSFTrack tracks[MAXTRACK];  // track 0 isn't valid; technically can be considered the lead-in
};

//-----------------------------------------------------------------
// psfpga_to_lba: MM:SS:FF to sector
//-----------------------------------------------------------------
static inline uint32_t psfpga_to_lba(u24 pos)
{
     return (((uint32_t)pos.mm) * 60 * 75) + (((uint32_t)pos.ss) * 75) + pos.ff;
}
//-----------------------------------------------------------------
// psfpga_from_lba: sector to MM:SS:FF
//-----------------------------------------------------------------
void psfpga_from_lba(uint32_t lba, u24 *pos) 
{
    pos->mm = (int)lba / 60 / 75;
    pos->ss = ((int)lba % (60 * 75)) / 75;
    pos->ff = (int)lba % 75;
}
//-----------------------------------------------------------------
// psfpga_get_track_num: Get track from position
//-----------------------------------------------------------------
static inline int psfpga_get_track_num(struct PSFDisc *dsk, u24 pos)
{
    uint32_t off = psfpga_to_lba(pos);

    for (int i = 0; i < dsk->trackCount; i++)
    {
        uint32_t start = psfpga_to_lba(dsk->tracks[i].start);
        uint32_t size  = psfpga_to_lba(dsk->tracks[i].size);
        printf(" track: %d: LBA start %d size %d (off=%d)\n", i, start, size, off);

        if (off >= start && off < start + size)
            return i;
    }
    return -1;
}
//-----------------------------------------------------------------
// psfpga_get_sector_lba: Lookup LBA for position
//-----------------------------------------------------------------
static inline uint32_t psfpga_get_sector_lba(struct PSFDisc *dsk, u24 pos)
{
    int t = psfpga_get_track_num(dsk, pos);
    if (t < 0)
        return 0;

    if (t == 0 && dsk->tracks[t].trackType == TRACK_TYPE_DATA)
    {
        u24 base;
        base.mm = 0; base.ss = 2; base.ff = 0;
        return psfpga_to_lba(pos) - psfpga_to_lba(base);
    }
    else
        return psfpga_to_lba(pos);
}
//-----------------------------------------------------------------
// psfpga_get_sector: Get sector pointer (offset to start of binary)
//-----------------------------------------------------------------
static inline uint32_t psfpga_get_sector(struct PSFDisc *dsk, u24 pos, uint8_t *pType)
{
    int t = psfpga_get_track_num(dsk, pos);
    if (t < 0)
    {
        printf("psfpga_get_sector: out of range trace mm=%d ss=%d ff=%d\n", pos.mm, pos.ss, pos.ff);
        return 0;
    }

    uint32_t lba = psfpga_get_sector_lba(dsk, pos);
    printf("psfpga_get_sector: LBA %d\n", lba);
    printf("psfpga_get_sector: %d %d %d\n", pos.mm, pos.ss, pos.ff, dsk->tracks[t].offset + (lba * CD_SECT_SZ));

    if (pType)
        *pType = dsk->tracks[t].trackType;

    return dsk->tracks[t].offset + (lba * CD_SECT_SZ);
}

#endif