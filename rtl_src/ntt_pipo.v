`timescale 1ns / 1ps

module NTT_PIPO
# (parameter DEPTH = 5)
    (
    input clk,
    input en,
    input [95:0] datai,
    output [95:0] data0
    );
    
    reg [95:0] PIPO [DEPTH-1:0];
    
    assign data0 = PIPO[DEPTH-1];
        
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            PIPO[i] = 0;
    end

    always @(posedge clk) begin
        if (en) begin
            PIPO[0] <= datai;
            for (i = 0; i < DEPTH-1; i = i + 1)
                PIPO[i+1] <= PIPO[i];
        end
    
    end
    
    
    
endmodule
