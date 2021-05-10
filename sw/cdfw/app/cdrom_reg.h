#ifndef CDROM_REG_H
#define CDROM_REG_H

#include <stdint.h>
#include <stdbool.h>
#include "cdrom_reg_defs.h"

#ifndef CONFIG_CDROM_BASE
#error "CONFIG_CDROM_BASE not defined"
#endif

//-----------------------------------------------------------------
// Defines:
//-----------------------------------------------------------------

//-----------------------------------------------------------------
// Inlines
//-----------------------------------------------------------------

//-----------------------------------------------------------------
// cdrom_reg_write: Write a 32-bit value to the INT side of CDROM regs
//-----------------------------------------------------------------
static inline void cdrom_reg_write(uint32_t addr, uint32_t value)
{
    volatile uint32_t *regs = (volatile uint32_t *)(CONFIG_CDROM_BASE);
    regs[addr/4] = value;
}
//-----------------------------------------------------------------
// cdrom_reg_read: Read a 32-bit value from the INT side of CDROM regs
//-----------------------------------------------------------------
static inline uint32_t cdrom_reg_read(uint32_t addr)
{
    volatile uint32_t *regs = (volatile uint32_t *)(CONFIG_CDROM_BASE);
    return regs[addr/4];
}

//-----------------------------------------------------------------
// cdrom_reg_cmd: Pop pending command
//-----------------------------------------------------------------
static inline uint32_t cdrom_reg_cmd_pop(void)
{
    return cdrom_reg_read(INTCPU_COMMAND);
}
//-----------------------------------------------------------------
// cdrom_reg_cmd_valid: Command pending
//-----------------------------------------------------------------
static inline bool cdrom_reg_cmd_valid(uint32_t value)
{
    bool res = (value & (1 << INTCPU_COMMAND_VALID)) != 0;
    return res;
}
//-----------------------------------------------------------------
// cdrom_reg_cmd_value: Command byte
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_cmd_value(uint32_t value)
{
    return (uint8_t)value;
}
//-----------------------------------------------------------------
// cdrom_reg_param_ready: Param byte ready
//-----------------------------------------------------------------
static inline bool cdrom_reg_param_ready(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_FIFO_STATUS);
    return (value & (1 << INTCPU_FIFO_STATUS_PARAM_EMPTY)) == 0;
}
//-----------------------------------------------------------------
// cdrom_reg_param_pop: Get param byte (FIFO pop)
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_param_pop(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_PARAM);
    return (uint8_t)value;
}
//-----------------------------------------------------------------
// cdrom_reg_resp_push: Write a byte to the response FIFO
//-----------------------------------------------------------------
static inline void cdrom_reg_resp_push(uint8_t data)
{
    cdrom_reg_write(INTCPU_RESPONSE, data);
}
//-----------------------------------------------------------------
// cdrom_reg_data_push: Write a 32-bit word to the data FIFO
//-----------------------------------------------------------------
static inline void cdrom_reg_data_push(uint32_t data)
{
    cdrom_reg_write(INTCPU_DATA, data);
}
//-----------------------------------------------------------------
// cdrom_reg_get_audl_cdl: Audio volume
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_get_audl_cdl(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_VOL);
    return (uint8_t)(value >> INTCPU_VOL_AUDL_CDL_B);
}
//-----------------------------------------------------------------
// cdrom_reg_get_audl_cdr: Audio volume
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_get_audl_cdr(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_VOL);
    return (uint8_t)(value >> INTCPU_VOL_AUDL_CDR_B);
}
//-----------------------------------------------------------------
// cdrom_reg_get_audr_cdl: Audio volume
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_get_audr_cdl(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_VOL);
    return (uint8_t)(value >> INTCPU_VOL_AUDR_CDL_B);
}
//-----------------------------------------------------------------
// cdrom_reg_get_audr_cdr: Audio volume
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_get_audr_cdr(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_VOL);
    return (uint8_t)(value >> INTCPU_VOL_AUDR_CDR_B);
}
//-----------------------------------------------------------------
// cdrom_reg_get_events: Read pending events (which clears them)
//-----------------------------------------------------------------
static inline uint32_t cdrom_reg_get_events(void)
{
    return cdrom_reg_read(INTCPU_EVENT);
}
//-----------------------------------------------------------------
// cdrom_reg_event_vol_apply: Extract volume update pending
//-----------------------------------------------------------------
static inline bool cdrom_reg_event_vol_apply(uint32_t value)
{
    return (value & (1 << INTCPU_EVENT_VOL_APPLY_B)) != 0;
}
//-----------------------------------------------------------------
// cdrom_reg_event_clr_vol_apply: Clear volume update pending
//-----------------------------------------------------------------
static inline uint32_t cdrom_reg_event_clr_vol_apply(uint32_t value)
{
    return value & ~(1 << INTCPU_EVENT_VOL_APPLY_B);
}
//-----------------------------------------------------------------
// cdrom_reg_get_adpmute: Read ADPMUTE
//-----------------------------------------------------------------
static inline bool cdrom_reg_get_adpmute(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_MISC_STATUS);
    return (value & (1 << INTCPU_MISC_STATUS_ADPMUTE_B)) != 0;
}
//-----------------------------------------------------------------
// cdrom_reg_get_bfrd: Read BFRD
//-----------------------------------------------------------------
static inline bool cdrom_reg_get_bfrd(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_MISC_STATUS);
    return (value & (1 << INTCPU_MISC_STATUS_BFRD_B)) != 0;
}

//-----------------------------------------------------------------
// cdrom_reg_param_empty: FIFO status
//-----------------------------------------------------------------
static inline bool cdrom_reg_param_empty(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_FIFO_STATUS);
    return (value & (1 << INTCPU_FIFO_STATUS_PARAM_EMPTY_B)) != 0;
}

//-----------------------------------------------------------------
// cdrom_reg_data_sector_space: Data FIFO has space for a sector
//-----------------------------------------------------------------
static inline bool cdrom_reg_data_sector_space(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_FIFO_STATUS);
    return (value & (1 << INTCPU_FIFO_STATUS_DATA_HALF_B)) != 0;
}

//-----------------------------------------------------------------
// cdrom_reg_data_sector_space_bytes: Space in the data FIFO
//-----------------------------------------------------------------
static inline uint16_t cdrom_reg_data_sector_space_bytes(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_FIFO_LEVEL);
    value >>= INTCPU_FIFO_LEVEL_DATA_B;
    return (1024 - value) * 4;
}

//-----------------------------------------------------------------
// cdrom_reg_get_intf: Read active (unACKd) interrupt flags
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_get_intf(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_MISC_STATUS);
    return (uint8_t)(value >> INTCPU_MISC_STATUS_INTF_B);
}
//-----------------------------------------------------------------
// cdrom_reg_raise_irq: Raise some interrupts
//-----------------------------------------------------------------
static inline void cdrom_reg_raise_irq(uint32_t data)
{
    while (cdrom_reg_get_intf() != 0)
        printf("Waiting for int space\n");

    cdrom_reg_write(INTCPU_RAISE, data);
}

//-----------------------------------------------------------------
// cdrom_reg_reset_busy: Reset the BUSYSTS status bit
//-----------------------------------------------------------------
static inline void cdrom_reg_reset_busy(void)
{
    cdrom_reg_write(INTCPU_RESET, 1 << INTCPU_RESET_BUSY_CLR_B);
}
//-----------------------------------------------------------------
// cdrom_reg_reset_resp_fifo: Reset the response FIFO
//-----------------------------------------------------------------
static inline void cdrom_reg_reset_resp_fifo(void)
{
    cdrom_reg_write(INTCPU_RESET, 1 << INTCPU_RESET_RESP_FIFO_B);
}
//-----------------------------------------------------------------
// cdrom_reg_reset_data_fifo: Reset the data FIFO
//-----------------------------------------------------------------
static inline void cdrom_reg_reset_data_fifo(void)
{
    cdrom_reg_write(INTCPU_RESET, 1 << INTCPU_RESET_DATA_FIFO_B);
}

//-----------------------------------------------------------------
// cdrom_reg_write_gpio: Write GPIO outputs
//-----------------------------------------------------------------
static inline void cdrom_reg_write_gpio(uint32_t value)
{
    cdrom_reg_write(INTCPU_GPIO, value);
}
//-----------------------------------------------------------------
// cdrom_reg_read_gpio: Read GPIO inputs
//-----------------------------------------------------------------
static inline uint32_t cdrom_reg_read_gpio(void)
{
    return cdrom_reg_read(INTCPU_GPIO);
}

//-----------------------------------------------------------------
// cdrom_reg_memcpy_available: Number of words available in buffer
//-----------------------------------------------------------------
static inline uint8_t cdrom_reg_memcpy_available(void)
{
    uint32_t value = cdrom_reg_read(INTCPU_DMA_STATUS);
    return (uint8_t)(value >> INTCPU_DMA_STATUS_LEVEL_B);
}
//-----------------------------------------------------------------
// cdrom_reg_memcpy: Copy from target memory a number of words
//-----------------------------------------------------------------
static inline void cdrom_reg_memcpy(uint32_t addr, uint32_t *buffer, int words)
{
    // NOTE: Fetch 8 word multiples
    for (int i=0;i<words;i+=8)
    {
        cdrom_reg_write(INTCPU_DMA_FETCH, addr);
        addr += (8 * 4);

        while (cdrom_reg_memcpy_available() < 8)
            ;

        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
        *buffer++ = cdrom_reg_read(INTCPU_DMA_FIFO);
    }
}

#endif