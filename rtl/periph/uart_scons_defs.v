//-----------------------------------------------------------------
// Copyright (c) 2021, admin@ultra-embedded.com
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions 
// are met:
//   - Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   - Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer 
//     in the documentation and/or other materials provided with the 
//     distribution.
//   - Neither the name of the author nor the names of its contributors 
//     may be used to endorse or promote products derived from this 
//     software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE 
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
// SUCH DAMAGE.
//-----------------------------------------------------------------
`define ATCONS_STAT    8'h0

    `define ATCONS_STAT_TX_READY      0
    `define ATCONS_STAT_TX_READY_DEFAULT    0
    `define ATCONS_STAT_TX_READY_B          0
    `define ATCONS_STAT_TX_READY_T          0
    `define ATCONS_STAT_TX_READY_W          1
    `define ATCONS_STAT_TX_READY_R          0:0

    `define ATCONS_STAT_RX_NOT_EMPTY      4
    `define ATCONS_STAT_RX_NOT_EMPTY_DEFAULT    0
    `define ATCONS_STAT_RX_NOT_EMPTY_B          4
    `define ATCONS_STAT_RX_NOT_EMPTY_T          4
    `define ATCONS_STAT_RX_NOT_EMPTY_W          1
    `define ATCONS_STAT_RX_NOT_EMPTY_R          4:4

`define ATCONS_TX    8'h2

    `define ATCONS_TX_DATA_DEFAULT    0
    `define ATCONS_TX_DATA_B          0
    `define ATCONS_TX_DATA_T          7
    `define ATCONS_TX_DATA_W          8
    `define ATCONS_TX_DATA_R          7:0

`define ATCONS_RX    8'h2

    `define ATCONS_RX_DATA_DEFAULT    0
    `define ATCONS_RX_DATA_B          0
    `define ATCONS_RX_DATA_T          7
    `define ATCONS_RX_DATA_W          8
    `define ATCONS_RX_DATA_R          7:0

