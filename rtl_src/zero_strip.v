`timescale 1ns / 1ps

module zero_strip# (
    parameter OUTPUT_W    = 4,
    parameter COEFF_W     = 23,
    parameter MAX_LVL     = 20,
    parameter W           = 64
    ) (
    input [4:0] encode_lvl,
    input [OUTPUT_W*COEFF_W-1:0] di,
    output reg [MAX_LVL*OUTPUT_W-1:0] dout
    );
    
    
    always @(*) begin
        dout = di[22:0] | (di[45:23] << encode_lvl) | (di[68:46] << {encode_lvl,1'd0}) | (di[91:69] << 3*encode_lvl);
    end
endmodule
