/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
 

module instruction_mem (
    input wire [31:0] address,
    output wire [31:0] instruction
);


reg [31:0] rom [0:1023]; 


initial begin
    $readmemh("../tb/programs/tb_program.hex", rom); 
end



assign instruction = rom[address[31:2]];

endmodule
