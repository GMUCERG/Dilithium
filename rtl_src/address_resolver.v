`timescale 1ns / 1ps

module address_resolver(
    input [1:0]      mapping,
    input [5:0]      addri,
    output reg [5:0] addro
    );
    
    localparam 
        DECODE_TRUE = 2'd0,
        ENCODE_TRUE = 2'd1,
        STANDARD    = 2'd2;
    
    always @(*) begin
        case(mapping)
        DECODE_TRUE: begin
            addro = {addri[3], addri[2], addri[1], addri[0], addri[5], addri[4]};
        end
        ENCODE_TRUE: begin
            addro = {addri[1], addri[0], addri[5], addri[4], addri[3], addri[2]};
        end
        STANDARD: begin
            addro = addri;
        end
        default: begin
            addro = addri;
        end
        endcase
    end
    
endmodule
