#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <linux/limits.h>
#include <assert.h>
#include <unistd.h>
#include <getopt.h>

#include "cue.h"
#include "cue_parser.h"

#include "psf_toc.h"

using namespace disc;
using namespace disc::format;

//-----------------------------------------------------------------
// Command line options
//-----------------------------------------------------------------
#define GETOPTS_ARGS "f:o:a"

static struct option long_options[] =
{
    {"cue",        required_argument, 0, 'f'},
    {"output",     required_argument, 0, 'o'},
    {"audio",      no_argument,       0, 'a'},
    {"help",       no_argument,       0, 'h'},
    {0, 0, 0, 0}
};

static void help_options(void)
{
    fprintf (stderr,"Usage:\n");
    fprintf (stderr,"  --cue        | -f FILE       Cue file to load\n");
    fprintf (stderr,"  --output     | -o BIN        PSF loader output file\n");
    fprintf (stderr,"  --audio      | -a            Include audio tracks\n");
    exit(-1);
}
//-----------------------------------------------------------------
// bin_load: Binary load
//-----------------------------------------------------------------
static uint8_t* bin_load(std::string filename, uint32_t &bin_size)
{
    // Load file
    FILE *f = fopen(filename.c_str(), "rb");
    if (f)
    {
        long size;
        uint8_t *buf;
        int error = 1;

        // Get size
        fseek(f, 0, SEEK_END);
        size = ftell(f);
        rewind(f);

        buf = new uint8_t[size];
        if (buf)
        {
            // Read file data in
            int len = fread(buf, 1, size, f);
            fclose(f);
            bin_size = (uint32_t)size;
            return buf;
        }

        return NULL;
    }
    else
    {
        fprintf (stderr,"Error: Could not open %s\n", filename.c_str());
        return NULL;
    }
}

//-----------------------------------------------------------------
// main
//-----------------------------------------------------------------
int main(int argc, char *argv[])
{
    const char *   filename       = NULL;
    const char *   out_file       = NULL;
    int            help           = 0;
    bool           enable_audio   = false;
    int c;

    int option_index = 0;
    while ((c = getopt_long (argc, argv, GETOPTS_ARGS, long_options, &option_index)) != -1)
    {
        switch(c)
        {
            case 'f':
                filename = optarg;
                break;
            case 'o':
                out_file = optarg;
                break;
            case 'a':
                enable_audio = true;
                break;
            case '?':
            default:
                help = 1;   
                break;
        }
    }

    if (help || (filename == NULL))
        help_options();

    char actualpath[PATH_MAX+1];
    char *ptr = realpath(filename, actualpath);

    CueParser parser;
    std::unique_ptr<Cue> cue = parser.parse(actualpath);
    int track_count = cue->getTrackCount();

    Position disk_size = cue->getDiskSize();

    // Build TOC sector
    struct PSFDisc toc;
    toc.trackCount = track_count;

    uint32_t game_offset = 2352; // TOC space    

    uint8_t *game = new uint8_t[(700 * 1024*1024)];

    for (int i=0;i<toc.trackCount;i++)
    {
        Track    t     = cue->tracks[i];
        Position start = cue->getTrackStart(i);
        Position len   = cue->getTrackLength(i);
        Position idx0  = *(t.index0);
        Position idx1  = t.index1;

        toc.tracks[i].offset     = game_offset;

        toc.tracks[i].start.mm = start.mm;
        toc.tracks[i].start.ss = start.ss;
        toc.tracks[i].start.ff = start.ff;

        toc.tracks[i].size.mm = len.mm;
        toc.tracks[i].size.ss = len.ss;
        toc.tracks[i].size.ff = len.ff;

        toc.tracks[i].indices[0].mm = idx0.mm;
        toc.tracks[i].indices[0].ss = idx0.ss;
        toc.tracks[i].indices[0].ff = idx0.ff;
        toc.tracks[i].indices[1].mm = idx1.mm;
        toc.tracks[i].indices[1].ss = idx1.ss;
        toc.tracks[i].indices[1].ff = idx1.ff;
        toc.tracks[i].indexCount = t.index0 ? 2 : 1;

        if (t.type == disc::TrackType::DATA)
            toc.tracks[i].trackType = TRACK_TYPE_DATA;
        else
            toc.tracks[i].trackType = TRACK_TYPE_AUDIO;

        // Allocate space for data
        if (enable_audio || (t.type == disc::TrackType::DATA))
        {
            uint32_t track_sz   = 0;
            uint8_t *track_data = bin_load(t.filename.c_str(), track_sz);
            memcpy(&game[game_offset], track_data, track_sz);
            delete [] track_data;
            game_offset += (t.frames * 2352);
        }
    }

    toc.diskSize = game_offset;
    memcpy(&game[0], &toc, 2352);

    // Write file data
    printf("Creating file %s\n", out_file);
    FILE *f = fopen(out_file, "wb");
    if (f)
    {
        fwrite(game, 1, game_offset, f);
        fclose(f);
    }
    else
        printf("ERROR: Could not write output file\n");
    delete [] game;

    return 0;
}

