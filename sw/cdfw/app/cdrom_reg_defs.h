#ifndef CDROM_REG_DEFS_H
#define CDROM_REG_DEFS_H

#define INTCPU_COMMAND    0x0

    #define INTCPU_COMMAND_DATA_DEFAULT    0
    #define INTCPU_COMMAND_DATA_B          0
    #define INTCPU_COMMAND_DATA_T          7
    #define INTCPU_COMMAND_DATA_W          8

    #define INTCPU_COMMAND_VALID      8
    #define INTCPU_COMMAND_VALID_DEFAULT    0
    #define INTCPU_COMMAND_VALID_B          8
    #define INTCPU_COMMAND_VALID_T          8
    #define INTCPU_COMMAND_VALID_W          1

#define INTCPU_PARAM    0x4

    #define INTCPU_PARAM_DATA_DEFAULT    0
    #define INTCPU_PARAM_DATA_B          0
    #define INTCPU_PARAM_DATA_T          7
    #define INTCPU_PARAM_DATA_W          8

    #define INTCPU_PARAM_VALID      8
    #define INTCPU_PARAM_VALID_DEFAULT    0
    #define INTCPU_PARAM_VALID_B          8
    #define INTCPU_PARAM_VALID_T          8
    #define INTCPU_PARAM_VALID_W          1

#define INTCPU_RESPONSE    0x8

    #define INTCPU_RESPONSE_DATA_DEFAULT    0
    #define INTCPU_RESPONSE_DATA_B          0
    #define INTCPU_RESPONSE_DATA_T          7
    #define INTCPU_RESPONSE_DATA_W          8

#define INTCPU_DATA    0xc

    #define INTCPU_DATA_DATA_DEFAULT    0
    #define INTCPU_DATA_DATA_B          0
    #define INTCPU_DATA_DATA_T          31
    #define INTCPU_DATA_DATA_W          32

#define INTCPU_VOL    0x10

    #define INTCPU_VOL_AUDL_CDL_DEFAULT    0
    #define INTCPU_VOL_AUDL_CDL_B          0
    #define INTCPU_VOL_AUDL_CDL_T          7
    #define INTCPU_VOL_AUDL_CDL_W          8

    #define INTCPU_VOL_AUDL_CDR_DEFAULT    0
    #define INTCPU_VOL_AUDL_CDR_B          8
    #define INTCPU_VOL_AUDL_CDR_T          15
    #define INTCPU_VOL_AUDL_CDR_W          8

    #define INTCPU_VOL_AUDR_CDL_DEFAULT    0
    #define INTCPU_VOL_AUDR_CDL_B          16
    #define INTCPU_VOL_AUDR_CDL_T          23
    #define INTCPU_VOL_AUDR_CDL_W          8

    #define INTCPU_VOL_AUDR_CDR_DEFAULT    0
    #define INTCPU_VOL_AUDR_CDR_B          24
    #define INTCPU_VOL_AUDR_CDR_T          31
    #define INTCPU_VOL_AUDR_CDR_W          8

#define INTCPU_MISC_STATUS    0x14

    #define INTCPU_MISC_STATUS_ADPMUTE      0
    #define INTCPU_MISC_STATUS_ADPMUTE_DEFAULT    0
    #define INTCPU_MISC_STATUS_ADPMUTE_B          0
    #define INTCPU_MISC_STATUS_ADPMUTE_T          0
    #define INTCPU_MISC_STATUS_ADPMUTE_W          1

    #define INTCPU_MISC_STATUS_SMEN      1
    #define INTCPU_MISC_STATUS_SMEN_DEFAULT    0
    #define INTCPU_MISC_STATUS_SMEN_B          1
    #define INTCPU_MISC_STATUS_SMEN_T          1
    #define INTCPU_MISC_STATUS_SMEN_W          1

    #define INTCPU_MISC_STATUS_BFWR      2
    #define INTCPU_MISC_STATUS_BFWR_DEFAULT    0
    #define INTCPU_MISC_STATUS_BFWR_B          2
    #define INTCPU_MISC_STATUS_BFWR_T          2
    #define INTCPU_MISC_STATUS_BFWR_W          1

    #define INTCPU_MISC_STATUS_BFRD      3
    #define INTCPU_MISC_STATUS_BFRD_DEFAULT    0
    #define INTCPU_MISC_STATUS_BFRD_B          3
    #define INTCPU_MISC_STATUS_BFRD_T          3
    #define INTCPU_MISC_STATUS_BFRD_W          1

    #define INTCPU_MISC_STATUS_INTF_DEFAULT    0
    #define INTCPU_MISC_STATUS_INTF_B          8
    #define INTCPU_MISC_STATUS_INTF_T          15
    #define INTCPU_MISC_STATUS_INTF_W          8

#define INTCPU_MISC_CTRL    0x18

    #define INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT      0
    #define INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT_DEFAULT    0
    #define INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT_B          0
    #define INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT_T          0
    #define INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT_W          1

    #define INTCPU_MISC_CTRL_BFRD_CLR_INHIBIT      1
    #define INTCPU_MISC_CTRL_BFRD_CLR_INHIBIT_DEFAULT    0
    #define INTCPU_MISC_CTRL_BFRD_CLR_INHIBIT_B          1
    #define INTCPU_MISC_CTRL_BFRD_CLR_INHIBIT_T          1
    #define INTCPU_MISC_CTRL_BFRD_CLR_INHIBIT_W          1


#define INTCPU_EVENT    0x1c

    #define INTCPU_EVENT_COMMAND_WR      0
    #define INTCPU_EVENT_COMMAND_WR_DEFAULT    0
    #define INTCPU_EVENT_COMMAND_WR_B          0
    #define INTCPU_EVENT_COMMAND_WR_T          0
    #define INTCPU_EVENT_COMMAND_WR_W          1

    #define INTCPU_EVENT_PARAM_WR      1
    #define INTCPU_EVENT_PARAM_WR_DEFAULT    0
    #define INTCPU_EVENT_PARAM_WR_B          1
    #define INTCPU_EVENT_PARAM_WR_T          1
    #define INTCPU_EVENT_PARAM_WR_W          1

    #define INTCPU_EVENT_REQUEST_WR      2
    #define INTCPU_EVENT_REQUEST_WR_DEFAULT    0
    #define INTCPU_EVENT_REQUEST_WR_B          2
    #define INTCPU_EVENT_REQUEST_WR_T          2
    #define INTCPU_EVENT_REQUEST_WR_W          1

    #define INTCPU_EVENT_VOL_APPLY      3
    #define INTCPU_EVENT_VOL_APPLY_DEFAULT    0
    #define INTCPU_EVENT_VOL_APPLY_B          3
    #define INTCPU_EVENT_VOL_APPLY_T          3
    #define INTCPU_EVENT_VOL_APPLY_W          1

    #define INTCPU_EVENT_SND_MAP_DAT_WR      4
    #define INTCPU_EVENT_SND_MAP_DAT_WR_DEFAULT    0
    #define INTCPU_EVENT_SND_MAP_DAT_WR_B          4
    #define INTCPU_EVENT_SND_MAP_DAT_WR_T          4
    #define INTCPU_EVENT_SND_MAP_DAT_WR_W          1

    #define INTCPU_EVENT_SND_MAP_CDI_WR      5
    #define INTCPU_EVENT_SND_MAP_CDI_WR_DEFAULT    0
    #define INTCPU_EVENT_SND_MAP_CDI_WR_B          5
    #define INTCPU_EVENT_SND_MAP_CDI_WR_T          5
    #define INTCPU_EVENT_SND_MAP_CDI_WR_W          1

#define INTCPU_RAISE    0x20

    #define INTCPU_RAISE_INT_STS_DEFAULT    0
    #define INTCPU_RAISE_INT_STS_B          0
    #define INTCPU_RAISE_INT_STS_T          7
    #define INTCPU_RAISE_INT_STS_W          8

#define INTCPU_FIFO_STATUS    0x24

    #define INTCPU_FIFO_STATUS_PARAM_EMPTY      0
    #define INTCPU_FIFO_STATUS_PARAM_EMPTY_DEFAULT    0
    #define INTCPU_FIFO_STATUS_PARAM_EMPTY_B          0
    #define INTCPU_FIFO_STATUS_PARAM_EMPTY_T          0
    #define INTCPU_FIFO_STATUS_PARAM_EMPTY_W          1

    #define INTCPU_FIFO_STATUS_PARAM_FULL      1
    #define INTCPU_FIFO_STATUS_PARAM_FULL_DEFAULT    0
    #define INTCPU_FIFO_STATUS_PARAM_FULL_B          1
    #define INTCPU_FIFO_STATUS_PARAM_FULL_T          1
    #define INTCPU_FIFO_STATUS_PARAM_FULL_W          1

    #define INTCPU_FIFO_STATUS_RESPONSE_EMPTY      2
    #define INTCPU_FIFO_STATUS_RESPONSE_EMPTY_DEFAULT    0
    #define INTCPU_FIFO_STATUS_RESPONSE_EMPTY_B          2
    #define INTCPU_FIFO_STATUS_RESPONSE_EMPTY_T          2
    #define INTCPU_FIFO_STATUS_RESPONSE_EMPTY_W          1

    #define INTCPU_FIFO_STATUS_RESPONSE_FULL      3
    #define INTCPU_FIFO_STATUS_RESPONSE_FULL_DEFAULT    0
    #define INTCPU_FIFO_STATUS_RESPONSE_FULL_B          3
    #define INTCPU_FIFO_STATUS_RESPONSE_FULL_T          3
    #define INTCPU_FIFO_STATUS_RESPONSE_FULL_W          1

    #define INTCPU_FIFO_STATUS_DATA_EMPTY      4
    #define INTCPU_FIFO_STATUS_DATA_EMPTY_DEFAULT    0
    #define INTCPU_FIFO_STATUS_DATA_EMPTY_B          4
    #define INTCPU_FIFO_STATUS_DATA_EMPTY_T          4
    #define INTCPU_FIFO_STATUS_DATA_EMPTY_W          1

    #define INTCPU_FIFO_STATUS_DATA_FULL      5
    #define INTCPU_FIFO_STATUS_DATA_FULL_DEFAULT    0
    #define INTCPU_FIFO_STATUS_DATA_FULL_B          5
    #define INTCPU_FIFO_STATUS_DATA_FULL_T          5
    #define INTCPU_FIFO_STATUS_DATA_FULL_W          1

    #define INTCPU_FIFO_STATUS_DATA_HALF      6
    #define INTCPU_FIFO_STATUS_DATA_HALF_DEFAULT    0
    #define INTCPU_FIFO_STATUS_DATA_HALF_B          6
    #define INTCPU_FIFO_STATUS_DATA_HALF_T          6
    #define INTCPU_FIFO_STATUS_DATA_HALF_W          1

#define INTCPU_FIFO_LEVEL    0x28

    #define INTCPU_FIFO_LEVEL_PARAM_DEFAULT    0
    #define INTCPU_FIFO_LEVEL_PARAM_B          0
    #define INTCPU_FIFO_LEVEL_PARAM_T          7
    #define INTCPU_FIFO_LEVEL_PARAM_W          8

    #define INTCPU_FIFO_LEVEL_RESPONSE_DEFAULT    0
    #define INTCPU_FIFO_LEVEL_RESPONSE_B          8
    #define INTCPU_FIFO_LEVEL_RESPONSE_T          15
    #define INTCPU_FIFO_LEVEL_RESPONSE_W          8

    #define INTCPU_FIFO_LEVEL_DATA_DEFAULT    0
    #define INTCPU_FIFO_LEVEL_DATA_B          16
    #define INTCPU_FIFO_LEVEL_DATA_T          31
    #define INTCPU_FIFO_LEVEL_DATA_W          16

#define INTCPU_RESET    0x2c

    #define INTCPU_RESET_BUSY_CLR      0
    #define INTCPU_RESET_BUSY_CLR_DEFAULT    0
    #define INTCPU_RESET_BUSY_CLR_B          0
    #define INTCPU_RESET_BUSY_CLR_T          0
    #define INTCPU_RESET_BUSY_CLR_W          1

    #define INTCPU_RESET_PARAM_FIFO      1
    #define INTCPU_RESET_PARAM_FIFO_DEFAULT    0
    #define INTCPU_RESET_PARAM_FIFO_B          1
    #define INTCPU_RESET_PARAM_FIFO_T          1
    #define INTCPU_RESET_PARAM_FIFO_W          1

    #define INTCPU_RESET_RESP_FIFO      2
    #define INTCPU_RESET_RESP_FIFO_DEFAULT    0
    #define INTCPU_RESET_RESP_FIFO_B          2
    #define INTCPU_RESET_RESP_FIFO_T          2
    #define INTCPU_RESET_RESP_FIFO_W          1

    #define INTCPU_RESET_DATA_FIFO      3
    #define INTCPU_RESET_DATA_FIFO_DEFAULT    0
    #define INTCPU_RESET_DATA_FIFO_B          3
    #define INTCPU_RESET_DATA_FIFO_T          3
    #define INTCPU_RESET_DATA_FIFO_W          1

    #define INTCPU_RESET_CDROM      31
    #define INTCPU_RESET_CDROM_DEFAULT    0
    #define INTCPU_RESET_CDROM_B          31
    #define INTCPU_RESET_CDROM_T          31
    #define INTCPU_RESET_CDROM_W          1

#define INTCPU_GPIO    0x30

    #define INTCPU_GPIO_OUTPUT_DEFAULT    0
    #define INTCPU_GPIO_OUTPUT_B          0
    #define INTCPU_GPIO_OUTPUT_T          31
    #define INTCPU_GPIO_OUTPUT_W          32

#define INTCPU_DMA_FETCH    0x34

    #define INTCPU_DMA_FETCH_ADDR_DEFAULT    0
    #define INTCPU_DMA_FETCH_ADDR_B          0
    #define INTCPU_DMA_FETCH_ADDR_T          31
    #define INTCPU_DMA_FETCH_ADDR_W          32

#define INTCPU_DMA_FIFO     0x38

    #define INTCPU_DMA_FIFO_DATA_DEFAULT    0
    #define INTCPU_DMA_FIFO_DATA_B          0
    #define INTCPU_DMA_FIFO_DATA_T          31
    #define INTCPU_DMA_FIFO_DATA_W          32

#define INTCPU_DMA_STATUS   0x3c

    #define INTCPU_DMA_STATUS_LEVEL_DEFAULT    0
    #define INTCPU_DMA_STATUS_LEVEL_B          0
    #define INTCPU_DMA_STATUS_LEVEL_T          3
    #define INTCPU_DMA_STATUS_LEVEL_W          4
    #define INTCPU_DMA_STATUS_BUSY_DEFAULT     0
    #define INTCPU_DMA_STATUS_BUSY_B           31
    #define INTCPU_DMA_STATUS_BUSY_T           31
    #define INTCPU_DMA_STATUS_BUSY_W           1

#define INTCPU_DEBUG0    0x40

#endif