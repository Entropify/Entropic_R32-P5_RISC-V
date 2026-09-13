/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module soc_top #(
    parameter INSTR_MEM_FILE = "../../tb/programs/tb_program.hex"
)(
    input wire clk,
    input wire rst_n,
    output wire halt,
    output wire [31:0] x10_debug,
    output wire [31:0] pc_debug,
    output wire uart_tx
);


// instr mem bus

wire [31:0] instr_address;
wire [31:0] instruction;


// data mem bus

wire [31:0] data_address;
wire [31:0] data_read_address;
wire data_read_enable;
wire [31:0] data_write;
wire [31:0] data_read;
wire mem_write;
wire mem_read;
wire [3:0] write_mask;


// UART MMIO decode
//
// The UART lives at 0x1000_0000, far outside the 4K data RAM (0x0..0xFFF).
// A store there is the TX byte (low 8 bits of the stored word); a load there
// returns the status word {31'b0, tx_busy}. RAM strobes are masked off for
// that address so a UART access never touches memory.
//
// Two decodes are needed because the synchronous data memory samples its read
// address one stage early: stores are decoded from the MEM-stage address
// (data_address), loads from the EX-stage read address (data_read_address).

wire uart_sel    = (data_address[31:28] == 4'h1);        // MEM-stage (stores)
wire ex_uart_sel = (data_read_address[31:28] == 4'h1);   // EX-stage (loads)

wire uart_write = mem_write && uart_sel;
wire uart_read  = mem_read  && uart_sel;
wire uart_busy;

wire ram_mem_write   = mem_write && !uart_sel;
wire ram_read_enable = data_read_enable && !ex_uart_sel;

wire [31:0] ram_read_data;

assign data_read = uart_read ? {31'b0, uart_busy} : ram_read_data;


// uart transmitter (write = send byte, read = busy flag)

uart_tx #(
    .CLKS_PER_BIT(434)          // 50 MHz / 115200 baud
) uart (
    .clk(clk),
    .rst_n(rst_n),
    .tx_start(uart_write && !uart_busy),
    .tx_data(data_write[7:0]),
    .tx(uart_tx),
    .tx_busy(uart_busy)
);


// rv32i cpu

rv32i_core cpu (
    .clk(clk),
    .rst_n(rst_n),

    .instr_address(instr_address),
    .instruction(instruction),

    .data_address(data_address),
    .data_read_address(data_read_address),
    .data_read_enable(data_read_enable),
    .data_write(data_write),
    .data_read(data_read),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .write_mask(write_mask),
    .halt(halt),
    .x10_debug(x10_debug),
    .pc_debug(pc_debug)
    );


// instr mem

instruction_mem #(
    .INIT_FILE(INSTR_MEM_FILE)
) rom (
        .address(instr_address),
        .instruction(instruction)
    );


// data mem (synchronous read, sampled in EX)

    data_mem #(
        .INIT_FILE(INSTR_MEM_FILE)   // preload the same image so .rodata is readable
    ) ram (
        .clk(clk),
        .mem_write(ram_mem_write),
        .read_enable(ram_read_enable),
        .read_address(data_read_address),
        .write_address(data_address),
        .write_data(data_write),
        .write_mask(write_mask),
        .read_data(ram_read_data)
    );

endmodule
