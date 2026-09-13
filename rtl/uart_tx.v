/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * uart_tx — simple UART transmitter (8 data bits, no parity, 1 stop bit).
 *
 * A one-cycle pulse on tx_start latches tx_data and shifts it out LSB-first,
 * holding each bit for CLKS_PER_BIT clocks. tx is idle-high, so the line rests
 * at logic 1 and the start bit is the falling edge. tx_busy is high for the
 * whole frame so a writer can poll before starting the next byte (the SoC
 * exposes tx_busy as bit 0 of the UART MMIO read word).
 *
 * CLKS_PER_BIT = f_clk / baud. The SoC runs at 50 MHz, so 434 -> ~115200 baud.
 */

`default_nettype none

module uart_tx #(
    parameter CLKS_PER_BIT = 434
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,     // one-cycle pulse: latch tx_data and send
    input  wire [7:0] tx_data,      // byte to transmit
    output reg        tx,           // serial output line (idle high)
    output reg        tx_busy       // high while a frame is in flight
);

localparam [1:0] IDLE  = 2'd0,
                 START = 2'd1,
                 DATA  = 2'd2,
                 STOP  = 2'd3;

reg [1:0]  state;
reg [15:0] clk_count;
reg [2:0]  bit_index;
reg [7:0]  data_shift;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        state      <= IDLE;
        clk_count  <= 16'd0;
        bit_index  <= 3'd0;
        data_shift <= 8'd0;
        tx         <= 1'b1;
        tx_busy    <= 1'b0;
    end

    else begin

        case (state)

            IDLE: begin
                tx        <= 1'b1;
                clk_count <= 16'd0;
                bit_index <= 3'd0;

                if (tx_start) begin
                    data_shift <= tx_data;
                    tx_busy    <= 1'b1;
                    state      <= START;
                end

                else begin
                    tx_busy <= 1'b0;
                end
            end

            START: begin
                tx <= 1'b0;                     // start bit

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 16'd0;
                    state     <= DATA;
                end

                else begin
                    clk_count <= clk_count + 16'd1;
                end
            end

            DATA: begin
                tx <= data_shift[0];            // LSB first

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count  <= 16'd0;
                    data_shift <= {1'b0, data_shift[7:1]};

                    if (bit_index == 3'd7) begin
                        bit_index <= 3'd0;
                        state     <= STOP;
                    end

                    else begin
                        bit_index <= bit_index + 3'd1;
                    end
                end

                else begin
                    clk_count <= clk_count + 16'd1;
                end
            end

            STOP: begin
                tx <= 1'b1;                     // stop bit

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 16'd0;
                    tx_busy   <= 1'b0;
                    state     <= IDLE;
                end

                else begin
                    clk_count <= clk_count + 16'd1;
                end
            end

            default: state <= IDLE;

        endcase
    end
end

endmodule
