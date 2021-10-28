`timescale 1ns / 1ps

module decomposer_unit #(
    parameter OUTPUT_W    = 4,
    parameter COEFF_W     = 24
    ) (
    input rst,
    input clk,
    input [2:0] sec_lvl,
    input  valid_i,
    output ready_i,
    input  [OUTPUT_W*COEFF_W-1:0] di,
    output [OUTPUT_W*COEFF_W-1:0] doa,
    output [OUTPUT_W*COEFF_W-1:0] dob,
    output valid_o,
    input ready_o
    );
    
    wire [0:OUTPUT_W-1] valid_coeff_o;
    assign valid_o = &valid_coeff_o;
    wire [OUTPUT_W-1:0] ready_i_sub;
    assign ready_i = |ready_i_sub;
    
    
    genvar i;
    generate
        for (i = 0; i < OUTPUT_W; i = i + 1) begin
            coeff_decomposer COEFF_DECOMP(
                rst, clk, valid_i, ready_i_sub[i], sec_lvl, di[24*i+:24],
                doa[24*i+:24], dob[24*i+:24], valid_coeff_o[i], ready_o
            );
        end
        
    endgenerate
    
endmodule
