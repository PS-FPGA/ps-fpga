#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#include "timer.h"
#include "assert.h"
#include "cdrom_reg.h"
#include "psf_toc.h"

//-----------------------------------------------------------------
// Defines
//-----------------------------------------------------------------
#define GAMESTORE_BASE 0x04000000
#define SECTOR_SIZE    2352

#define raise_irq_data() cdrom_reg_raise_irq(1)
#define raise_irq_comp() cdrom_reg_raise_irq(2)
#define raise_irq_ack()  cdrom_reg_raise_irq(3)
#define raise_irq_err()  cdrom_reg_raise_irq(5)

//-----------------------------------------------------------------
// Types
//-----------------------------------------------------------------
enum
{
    ERROR_REASON_NOT_READY                      = 0x80,
    ERROR_CODE_INVALID_COMMAND                  = 0x40,
    ERROR_REASON_INCORRECT_NUMBER_OF_PARAMETERS = 0x20,
    ERROR_REASON_INVALID_ARGUMENT               = 0x10,
};

enum
{
    // WARNING : NEVER STORE IN SSR STATUS !!!!
    // SPIKE during result sent to PSX, use | to send it.
    HAS_ERROR       = 0x01,

    IS_MOTOR_ON     = 0x02,
    SEEK_ERROR      = 0x04,
    ID_ERROR        = 0x08,
    SHELL_OPEN      = 0x10,
    STAT_READING    = 0x20,
    STAT_SEEKING    = 0x40,
    STAT_PLAYING    = 0x80  // CDDA
};

#define STAT_NONE   0

enum
{
    MODE_CDDA_EN    = 0x01,
    MODE_CDDA_AP    = 0x02,
    MODE_CDDA_REP   = 0x04,
    MODE_XA_FILT    = 0x08,
    MODE_SKIPMODE   = 0x10,
    MODE_SEC_2340   = 0x20,
    MODE_XA_EN      = 0x40,
    MODE_DSPEED     = 0x80
};

enum
{
    SUBMODE_ENDOFRECORD = 0x01,
    SUBMODE_VIDEO       = 0x02,
    SUBMODE_AUDIO       = 0x04,
    SUBMODE_DATA        = 0x08,
    SUBMODE_TRIGGER     = 0x10,
    SUBMODE_FORM2       = 0x20,
    SUBMODE_REALTIME    = 0x40,
    SUBMODE_ENDOFFILE   = 0x80
};

//-----------------------------------------------------------------
// Locals
//-----------------------------------------------------------------
static uint8_t  m_params[16];
static int      m_param_count;
static uint8_t  m_status;
static int      m_mute;
static int      m_current_lba;
static uint8_t  m_drive_mode;
static uint8_t  m_sector_skip;
static uint16_t m_sector_length;
static uint32_t m_buffer[(SECTOR_SIZE/4) + 64];
static uint32_t *m_buffer_ptr;
static int      m_buf_valid;
static int      m_buf_sector;
static struct PSFDisc m_toc;
static uint8_t  m_filter_file;
static uint8_t  m_filter_channel;
static int      m_scex_counter;

//-----------------------------------------------------------------
// cdrom_set_debug: Stash some interesting state in a register
//-----------------------------------------------------------------
static inline void cdrom_set_debug(uint8_t status, uint8_t mode, int current_lba)
{
    uint32_t value = current_lba & 0xFFFFF;
    if (mode & MODE_SEC_2340)
        value |= 1 << 20;
    value |= ((uint32_t)m_status) << 24;
    cdrom_reg_write(INTCPU_DEBUG0, value);
}
//-----------------------------------------------------------------
// cdrom_load_from_gamestore: Load a sector direct from gamestore
//-----------------------------------------------------------------
static void cdrom_load_sector(int sector)
{
    uint32_t addr = GAMESTORE_BASE + (sector * SECTOR_SIZE);
    uint32_t *p   = m_buffer;

    printf("[CDROM_FW] Load from gamestore sector %d @ 0x%08x\n", sector, addr);

    if (addr & 0x10)
        m_buffer_ptr = &m_buffer[4];
    else
        m_buffer_ptr = &m_buffer[0];

    addr &= ~(32-1);

    for (int i=0;i<(SECTOR_SIZE+32);i+=32)
    {
        cdrom_reg_memcpy(addr, p, 8);
        addr += 32;
        p += 8;
    }

    m_buf_valid  = 1;
    m_buf_sector = sector;
}
//-----------------------------------------------------------------
// cdrom_consume_buffer: Copy sector to FIFO
//-----------------------------------------------------------------
static void cdrom_consume_buffer(void)
{
    uint32_t *p   = m_buffer_ptr;
    uint16_t  len = m_sector_length;

    uint8_t submode = m_buffer_ptr[4] >> 16;

    // TODO: No SPU for now...
    //if ((m_drive_mode & MODE_XA_EN) && (submode & SUBMODE_AUDIO) && (submode & SUBMODE_REALTIME))
    //{
    //    printf("[CDROM_FW] XA_ADPCM sector %d ditched [submode=%x]\n", m_buf_sector, submode);
    //    m_buf_valid = 0;
    //    return ;
    //}

    printf("[CDROM_FW] Transfer sector %d (%d bytes) [submode=%x]\n", m_buf_sector, m_sector_length, submode);

    // 2048
    if (m_sector_length == 2048)
    {
        // Skip header
        p += (24 / 4);
    }
    // 2340
    else
    {
        //printf(" SECTOR: ");
        //for (int i=0;i<32/4;i++)
        //{
        //    printf("%08x ", p[i]);
        //}
        //printf("\n");

        // Skip header
        p += (12 / 4);

        len = m_sector_length;// - 280;
    }

    for (int i=0;i<len;i+=4)
        cdrom_reg_data_push(*p++);

    m_buf_valid = 0;

    // TODO: Handling of endoffile???
}
//-----------------------------------------------------------------
// Helpers
//-----------------------------------------------------------------
static uint8_t BCDtoBinary(uint8_t bcd)
{
    int hi = ((bcd >> 4) & 0xf);
    int lo = (bcd & 0xf);
    return (hi*10) + lo;
}
static uint8_t toBcd(uint8_t b)
{ 
    return ((b / 10) << 4) | (b % 10);
}
static void setState(uint8_t s)
{
    m_status &= ~(STAT_PLAYING | STAT_SEEKING | STAT_READING);
    m_status |= s;
}
//-----------------------------------------------------------------
// commandInitialize
//-----------------------------------------------------------------
static void commandInitialize(void)
{
    printf("[CDROM_FW] commandInitialize S\n");

    // Reset some FIFOs
    cdrom_reg_reset_data_fifo();
    m_buf_valid     = 0;

    m_drive_mode    = 0;
    m_sector_skip   = 0x18; 
    m_sector_length = 2048;
    m_status        = 0;
    m_mute          = false;

    printf("[CDROM_FW] commandInitialize: Send status %02x\n", m_status);
    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    timer_sleep(5);

    m_status |= IS_MOTOR_ON;
    printf("[CDROM_FW] commandInitialize: Send status %02x\n", m_status);
    cdrom_reg_resp_push(m_status);
    printf("[CDROM_FW] commandInitialize: Raise COMP\n");
    raise_irq_comp();
}
//-----------------------------------------------------------------
// commandGetStatus
//-----------------------------------------------------------------
static void commandGetStatus(void)
{
    printf("[CDROM_FW] commandGetStatus: Send status %02x\n", m_status);
    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandSetLocation
//-----------------------------------------------------------------
static void commandSetLocation(void)
{
    uint8_t minute = BCDtoBinary(m_params[0]);
    uint8_t second = BCDtoBinary(m_params[1]);
    uint8_t frame  = BCDtoBinary(m_params[2]);

    printf("[CDROM_FW] commandSetLocation S m=%d,s=%d,f=%d\n", minute, second, frame);

    // TODO: Avocado does not change reading state here...
    m_status &= ~STAT_READING; // Not reading.
    m_buf_valid = 0;

    u24 pos;
    pos.mm = minute;
    pos.ss = second;
    pos.ff = frame;

    uint8_t track_type;
    m_current_lba = psfpga_get_sector(&m_toc, pos, &track_type) / CD_SECT_SZ;
    printf("[CDROM_FW] commandSetLocation: LBA %d\n", m_current_lba);

    timer_sleep(1);
    while (cdrom_reg_get_intf() != 0)
        ;

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandSetMode
//-----------------------------------------------------------------
static void commandSetMode(void)
{
    m_drive_mode = m_params[0];

    printf("[CDROM_FW] commandSetMode S: mode = %x\n", m_drive_mode);

    if (m_drive_mode & MODE_SEC_2340)
        m_sector_length = 2340;
    else
        m_sector_length = 2048;
    
    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandReadN
//-----------------------------------------------------------------
static void commandReadN(void)
{
    printf("[CDROM_FW] commandReadN S BFRD=%d SPACE=%d\n", cdrom_reg_get_bfrd(), cdrom_reg_data_sector_space_bytes());
    cdrom_reg_reset_data_fifo();
    m_buf_valid = 0;

    setState(STAT_READING);

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandReadS
//-----------------------------------------------------------------
static void commandReadS(void)
{
    printf("[CDROM_FW] commandReadS S BFRD=%d SPACE=%d\n", cdrom_reg_get_bfrd(), cdrom_reg_data_sector_space_bytes());
    cdrom_reg_reset_data_fifo();
    m_buf_valid = 0;

    setState(STAT_READING);

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandPause
//-----------------------------------------------------------------
static void commandPause(void)
{
    printf("[CDROM_FW] commandPause S\n");

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    setState(STAT_NONE);
    m_buf_valid = 0;

    timer_sleep(1);
    while (cdrom_reg_get_intf() != 0)
        ;

    cdrom_reg_resp_push(m_status);
    raise_irq_comp();
}
//-----------------------------------------------------------------
// commandReadTOC
//-----------------------------------------------------------------
static void commandReadTOC(void)
{
    printf("[CDROM_FW] commandReadTOC S\n");

    // TODO: Do nothing for now...

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    timer_sleep(2);

    cdrom_reg_resp_push(m_status);
    raise_irq_comp();
}
//-----------------------------------------------------------------
// commandSeekL
//-----------------------------------------------------------------
static void commandSeekL(void)
{
    printf("[CDROM_FW] commandSeekL S\n");
    //m_current_lba = ...

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    setState(STAT_SEEKING);

    timer_sleep(1);
    while (cdrom_reg_get_intf() != 0)
        ;

    cdrom_reg_resp_push(m_status);
    raise_irq_comp();

    // TODO: Differs to avocado
    setState(STAT_NONE);
}
//-----------------------------------------------------------------
// commandSeekP
//-----------------------------------------------------------------
static void commandSeekP(void)
{
    printf("[CDROM_FW] commandSeekP S\n");
    //m_current_lba = ...

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    setState(STAT_SEEKING);

    timer_sleep(1);
    while (cdrom_reg_get_intf() != 0)
        ;

    cdrom_reg_resp_push(m_status);
    raise_irq_comp();

    setState(STAT_NONE);
}
//-----------------------------------------------------------------
// commandMotorOn
//-----------------------------------------------------------------
static void commandMotorOn(void)
{
    printf("[CDROM_FW] commandMotorOn S\n");
    m_status |= IS_MOTOR_ON;

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    timer_sleep(2);

    cdrom_reg_resp_push(m_status);
    raise_irq_comp();
}
//-----------------------------------------------------------------
// commandStop
//-----------------------------------------------------------------
static void commandStop(void)
{
    printf("[CDROM_FW] commandStop S\n");
    setState(STAT_NONE);
    m_status &= ~IS_MOTOR_ON;

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    timer_sleep(1);
    while (cdrom_reg_get_intf() != 0)
        ;

    cdrom_reg_resp_push(m_status);
    raise_irq_comp();
}
//-----------------------------------------------------------------
// commandUnmute
//-----------------------------------------------------------------
static void commandUnmute(void)
{
    printf("[CDROM_FW] commandUnmute S [NOT IMPLEMENTED]\n");
    m_mute = false;
    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandMute
//-----------------------------------------------------------------
static void commandMute(void)
{
    printf("[CDROM_FW] commandMute S [NOT IMPLEMENTED]\n");
    m_mute = true;
    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandGetID
//-----------------------------------------------------------------
static void commandGetID(void)
{
    printf("[CDROM_FW] commandGetID S\n");

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    timer_sleep(2);

#ifdef NO_DISK
    cdrom_reg_resp_push(0x40);
    for (int i = 0; i < 6; i++) 
        cdrom_reg_resp_push(0);
    raise_irq_err();
#else
    // Game CD
    cdrom_reg_resp_push(0x02);
    cdrom_reg_resp_push(0x00);
    cdrom_reg_resp_push(0x20);
    cdrom_reg_resp_push(0x00);
    cdrom_reg_resp_push('S');
    cdrom_reg_resp_push('C');
    cdrom_reg_resp_push('E');
    cdrom_reg_resp_push('A');  // 0x45 E, 0x41 A, 0x49 I
    raise_irq_comp();
#endif
}
//-----------------------------------------------------------------
// commandSetSession
//-----------------------------------------------------------------
static void commandSetSession(void)
{
    printf("[CDROM_FW] commandSetSession S [NOT IMPLEMENTED]\n");
    cdrom_reg_resp_push(m_status);
    raise_irq_ack();

    timer_sleep(2);

    cdrom_reg_resp_push(m_status);
    raise_irq_comp();
}
//-----------------------------------------------------------------
// commandGetFirstAndLastTrackNumbers
//-----------------------------------------------------------------
static void commandGetFirstAndLastTrackNumbers(void)
{
    printf("[CDROM_FW] commandGetFirstAndLastTrackNumbers S\n");

    cdrom_reg_resp_push(m_status);
    cdrom_reg_resp_push(toBcd(0x01));
    cdrom_reg_resp_push(toBcd(m_toc.trackCount));
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandGetTrackStart
//-----------------------------------------------------------------
static void commandGetTrackStart(void)
{
    printf("[CDROM_FW] commandGetTrackStart S\n");

    uint8_t track = BCDtoBinary(m_params[0]);
    printf("- track %02x\n", track);

    if (track == 0)
    {
        uint32_t lba = m_toc.diskSize / CD_SECT_SZ;
        u24      pos;
        psfpga_from_lba(lba, &pos);

        cdrom_reg_resp_push(m_status);
        cdrom_reg_resp_push(toBcd(pos.mm));
        cdrom_reg_resp_push(toBcd(pos.ss));
        raise_irq_ack();
    }
    else if (track <= m_toc.trackCount)
    {
        cdrom_reg_resp_push(m_status);
        cdrom_reg_resp_push(toBcd(m_toc.tracks[track-1].start.mm));
        cdrom_reg_resp_push(toBcd(m_toc.tracks[track-1].start.ss));
        raise_irq_ack();
    }
    else
    {
        cdrom_reg_resp_push(0x10);
        raise_irq_err();
        printf("[CDROM_FW] commandGetTrackStart: Error\n");
    }
}
//-----------------------------------------------------------------
// commandPlay
//-----------------------------------------------------------------
static void commandPlay(void)
{
    printf("[CDROM_FW] commandPlay S [NOT IMPLEMENTED]\n");

    // Location provided
    if (m_param_count)
    {
        int track = m_params[0];
        if (track >= m_toc.trackCount)
        {
            printf("[CDROM_FW] commandPlay - ERROR: invalid PLAY param\n");
            return ;
        }

        u24 pos;
        pos.mm = m_toc.tracks[track].start.mm;
        pos.ss = m_toc.tracks[track].start.ss;
        pos.ff = m_toc.tracks[track].start.ff;

        uint8_t track_type;
        m_current_lba = psfpga_get_sector(&m_toc, pos, &track_type) / CD_SECT_SZ;
    }

    setState(STAT_PLAYING);

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandSetFilter
//-----------------------------------------------------------------
static void commandSetFilter(void)
{
    printf("[CDROM_FW] commandSetFilter S [NOT IMPLEMENTED]\n");
    m_filter_file    = m_params[0];
    m_filter_channel = m_params[1];

    cdrom_reg_resp_push(m_status);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandGetParam
//-----------------------------------------------------------------
static void commandGetParam(void)
{
    printf("[CDROM_FW] commandGetParam S\n");
    cdrom_reg_resp_push(m_status);
    cdrom_reg_resp_push(m_drive_mode);
    cdrom_reg_resp_push(0x00);
    cdrom_reg_resp_push(m_filter_file);
    cdrom_reg_resp_push(m_filter_channel);
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandGetLocationPlaying
//-----------------------------------------------------------------
static void commandGetLocationPlaying(void)
{
    // TODO: Nonsense...
    printf("[CDROM_FW] commandGetLocationPlaying S [NOT IMPLEMENTED]\n");
    cdrom_reg_resp_push(0x01);  // track
    cdrom_reg_resp_push(0x01);  // index
    cdrom_reg_resp_push(0x00);  // minute (track)
    cdrom_reg_resp_push(0x02);  // second (track)
    cdrom_reg_resp_push(0x68);  // sector (track)
    cdrom_reg_resp_push(0x00);  // minute (disc)
    cdrom_reg_resp_push(0x04);  // second (disc)
    cdrom_reg_resp_push(0x68);  // sector (disc)
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandGetLocationL
//-----------------------------------------------------------------
static void commandGetLocationL(void)
{
    // TODO: Nonsense...
    printf("[CDROM_FW] commandGetLocationL S [NOT IMPLEMENTED]\n");
    uint8_t *p   = (uint8_t *)m_buffer_ptr;
    cdrom_reg_resp_push(p[12]);  // minute (track)
    cdrom_reg_resp_push(p[13]);  // second (track)
    cdrom_reg_resp_push(p[14]);  // sector (track)
    cdrom_reg_resp_push(p[15]);  // mode
    cdrom_reg_resp_push(p[16]);  // file
    cdrom_reg_resp_push(p[17]);  // channel
    cdrom_reg_resp_push(p[18]);  // sm
    cdrom_reg_resp_push(p[19]);  // ci
    raise_irq_ack();
}
//-----------------------------------------------------------------
// commandTest
//-----------------------------------------------------------------
static void commandTest(void)
{
    printf("[CDROM_FW] commandTest S [NOT IMPLEMENTED]\n");

    // Force motor off, used in swap
    if (m_params[0] == 0x03)
    {
        m_status &= ~IS_MOTOR_ON;

        cdrom_reg_resp_push(m_status);
        raise_irq_ack();
    }
    // Read SCEx string
    else if (m_params[0] == 0x04)
    {
        m_status |= IS_MOTOR_ON;

        m_scex_counter = 0;
        cdrom_reg_resp_push(m_status);
        raise_irq_ack();

        if (m_current_lba < 1024)
            m_scex_counter++;
    }
    // Get SCEx counters
    else if (m_params[0] == 0x05)
    {
        cdrom_reg_resp_push(m_scex_counter);
        cdrom_reg_resp_push(m_scex_counter);
        raise_irq_ack();
    }
    // Get CDROM BIOS date/version (yy,mm,dd,ver)
    else if (m_params[0] == 0x20)
    {
        cdrom_reg_resp_push(0x94);
        cdrom_reg_resp_push(0x09);
        cdrom_reg_resp_push(0x19);
        cdrom_reg_resp_push(0xc0);
        raise_irq_ack();
    }
    // Get CDROM BIOS region
    else if (m_params[0] == 0x22)
    {
        // Simulate SCEA bios
        cdrom_reg_resp_push('f');
        cdrom_reg_resp_push('o');
        cdrom_reg_resp_push('r');
        cdrom_reg_resp_push(' ');
        cdrom_reg_resp_push('U');
        cdrom_reg_resp_push('/');
        cdrom_reg_resp_push('C');
        raise_irq_ack();
    }
    else
    {
        assert(!"Not implemented");
        raise_irq_err();
    }
}

//-----------------------------------------------------------------
// Other Commands (not implemented)
//-----------------------------------------------------------------
static void commandInvalid(uint8_t errorCode)
{
    printf("[CDROM_FW] commandInvalid S\n");
    assert(!"Not implemented");
}
static void commandUnimplemented(uint8_t operation, uint8_t suboperation)
{
    printf("[CDROM_FW] commandUnimplemented S\n");
    assert(!"Not implemented");
}
static void commandUnimplementedNoSub(uint8_t operation)
{
    printf("[CDROM_FW] commandUnimplementedNoSub S\n");
    assert(!"Not implemented");
}

//-----------------------------------------------------------------
// main
//-----------------------------------------------------------------
int main(int argc, char *argv[])
{
    printf("[CDROM_FW] Booting...\n");

    cdrom_reg_write(INTCPU_MISC_CTRL, 1 << INTCPU_MISC_CTRL_BFRD_CLR_INHIBIT);

    m_drive_mode      = 0;
    m_sector_skip     = 0x18; 
    m_sector_length   = 2048;
    t_time t_last_sector = timer_now();

    // Make sure this pointer is always valid
    m_buffer_ptr      = &m_buffer[0];

    m_filter_file    = 0;
    m_filter_channel = 0;
    m_scex_counter   = 0;

    // Load table of contents
    cdrom_reg_memcpy(GAMESTORE_BASE, &m_toc, 2048/4);

    printf("NUM_TRACKS: %d\n", m_toc.trackCount);
    printf("Track 0 offset: %d\n", m_toc.tracks[0].offset);

    // Infinite loop...
    int toggle = 0;
    while (1)
    {
        uint32_t cmd_value = cdrom_reg_cmd_pop();

        if (cdrom_reg_cmd_valid(cmd_value))
        {
            uint8_t command = cmd_value;
            printf("[CDROM_FW] Command %02x\n", command);

            m_param_count = 0;
            while (!cdrom_reg_param_empty())
            {
                m_params[m_param_count++] = cdrom_reg_param_pop();
                printf("[CDROM_FW] Param: 0x%x\n", m_params[m_param_count-1]);
            }

            switch(command)
            {
            case 0x01: commandGetStatus();                      break;
            case 0x02: commandSetLocation();                    break;
            case 0x03: commandPlay();                           break;
            case 0x06: commandReadN();                          break;
            case 0x07: commandMotorOn();                        break;
            case 0x08: commandStop();                           break;
            case 0x09: commandPause();                          break;
            case 0x0a: commandInitialize();                     break;
            case 0x0b: commandMute();                           break;
            case 0x0c: commandUnmute();                         break;
            case 0x0d: commandSetFilter();                      break;
            case 0x0e: commandSetMode();                        break;
            case 0x0f: commandGetParam();                       break;
            case 0x10: commandGetLocationL();                   break;
            case 0x11: commandGetLocationPlaying();             break;
            case 0x12: commandSetSession();                     break;
            case 0x13: commandGetFirstAndLastTrackNumbers();    break;
            case 0x14: commandGetTrackStart();                  break;
            case 0x15: commandSeekL();                          break;
            case 0x16: commandSeekP();                          break;
            case 0x19: commandTest();                           break;
            case 0x1a: commandGetID();                          break;
            case 0x1b: commandReadS();                          break;
            case 0x1e: commandReadTOC();                        break;
            default: 
                commandInvalid(ERROR_CODE_INVALID_COMMAND);
                break;
            }

            cdrom_reg_reset_busy();
        }

        // Reading data and we have space for a sector
        if ((m_status & STAT_READING) && !m_buf_valid)
        {
            cdrom_load_sector(m_current_lba++);
        }

        // Reading data and we have space for a sector (and no interrupts pending)
        if (m_buf_valid && cdrom_reg_data_sector_space_bytes() == 4096 && cdrom_reg_get_intf() == 0)
        {
            if (timer_diff_ms(timer_now(), t_last_sector) >= 7)
            {
                cdrom_consume_buffer();

                cdrom_reg_resp_push(m_status);
                raise_irq_data();

                t_last_sector = timer_now();
            }
        }
        // Detect trailing crap left in buffer
        else if (m_buf_valid && cdrom_reg_get_intf() == 0 && (timer_diff_ms(timer_now(), t_last_sector) >= 7) && (4096 - cdrom_reg_data_sector_space_bytes()) != m_sector_length)
        {
            printf("[CDROM_FW] Dumping crap left in buffer (%d bytes)\n", 4096 - cdrom_reg_data_sector_space_bytes());
            cdrom_reg_reset_data_fifo();
        }
        else if (m_status & STAT_READING)
        {
            //printf("VALID: %d SPACE: %d BFRD %d INTF=%02x\n", m_buf_valid, cdrom_reg_data_sector_space_bytes(), cdrom_reg_get_bfrd(), cdrom_reg_get_intf());
        }

        toggle = !toggle;
        cdrom_reg_write_gpio(toggle);

        // Record details into debug register
        cdrom_set_debug(m_status, m_drive_mode, m_buf_sector);
    }

    return 0;
}