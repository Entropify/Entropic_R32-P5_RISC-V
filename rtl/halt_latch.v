/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module halt_latch(
    input wire clk,
    input wire rst_n,
    input wire halt_d,
    output reg halted
);

always @(posedge clk or negedge rst_n) begin
    
    if (!rst_n) begin
        halted <= 1'b0;
    end

    else begin
        halted <= halt_d | halted;
    end

end


endmodule
