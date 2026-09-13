/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Data memory. Two things are unusual here, both deliberate:
 *
 *  1) SYNCHRONOUS (BRAM-style) READ. read_address is the EX-stage ALU result,
 *     so the addressed word is captured on the clock edge and available in the
 *     *MEM* stage -- exactly when the asynchronous version used to produce it.
 *     That keeps all load/hazard/forwarding timing identical while replacing
 *     the deep, high-fanout asynchronous distributed-RAM mux tree (the
 *     critical-path bottleneck) with a fast clocked read.
 *       - read_enable (the EX-stage mem_read) suppresses reads of non-load
 *         instructions, so an arbitrary ALU result is never used as an address.
 *       - Write-first/read-second: a store in MEM and a load in EX to the SAME
 *         word must give the load the store's new value.
 *
 *  2) OPTIONAL PROGRAM-IMAGE PRELOAD (INIT_FILE). The instruction ROM and this
 *     RAM are two separate memories that BOTH live at address 0x0. The CPU
 *     fetches from the ROM, but reads data -- including .rodata string literals
 *     -- over the data bus, which lands here. With no initial contents, every
 *     string literal read returned garbage. Preloading the same image that the
 *     ROM uses puts the .rodata bytes (and any initialised .data) in RAM, so C
 *     code can use real string literals.
 *
 *     Caveat: .bss is not zeroed by the startup code (crt0 is minimal), so a
 *     global that is only *declared* still reads whatever this image left
 *     there. Initialise globals explicitly.
 */

`default_nettype none


 module data_mem #(
    parameter INIT_FILE = ""        // program image to preload; "" = leave blank
 )(
    input wire clk,
    input wire mem_write,
    input wire read_enable,   // EX-stage mem_read: only loads are actually read
    input wire [31:0] read_address,   // EX-stage address; sampled on clk edge
    input wire [31:0] write_address,  // MEM-stage address; used for stores
    input wire [31:0] write_data,
    input wire [3:0] write_mask,
    output reg [31:0] read_data
 );

reg [31:0] mem_array [0:1023];

initial begin
    if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, mem_array);
    end
end

always @(posedge clk) begin

    if (mem_write) begin

        if (write_mask[0]) mem_array[write_address[31:2]][7:0] <= write_data[7:0];

        if (write_mask[1]) mem_array[write_address[31:2]][15:8] <= write_data[15:8];

        if (write_mask[2]) mem_array[write_address[31:2]][23:16] <= write_data[23:16];

        if (write_mask[3]) mem_array[write_address[31:2]][31:24] <= write_data[31:24];

    end

    if (mem_write && read_enable && (write_address[31:2] == read_address[31:2])) begin
        read_data <= (write_mask[0] ? write_data[7:0]  : mem_array[read_address[31:2]][7:0])  |
                     (write_mask[1] ? write_data[15:8] : mem_array[read_address[31:2]][15:8]) |
                     (write_mask[2] ? write_data[23:16]: mem_array[read_address[31:2]][23:16])|
                     (write_mask[3] ? write_data[31:24]: mem_array[read_address[31:2]][31:24]);
    end
    else begin
        read_data <= read_enable ? mem_array[read_address[31:2]] : 32'b0;
    end

end

 endmodule
