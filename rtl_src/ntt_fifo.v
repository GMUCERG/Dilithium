`timescale 1ns / 1ps



module ntt_fifo(
    input clk,
    input rst,
    input en,
    input [2:0] mode,
    input [95:0] data_in,
    input [95:0] new_value,
    output reg [95:0] data_out
    );
    
    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1,
        MULT_MODE        = 3'd2,
        ADD_MODE         = 3'd3,
        SUB_MODE         = 3'd4;

    reg [1:0] count = 0;
    reg piso_ena, piso_enb, piso_enc, piso_end;
    wire [23:0] fifo_a, fifo_b, fifo_c, fifo_d;
    wire [95:0] fifo_outa, fifo_outb, fifo_outc, fifo_outd;
    
    ntt_fifo_piso #(.DEPTH(4))  PISO_A (
        clk, en, piso_ena, data_in, new_value[0*24+:24], fifo_outa, fifo_a
    );
    ntt_fifo_piso #(.DEPTH(6))  PISO_B (
        clk, en, piso_enb, data_in, new_value[1*24+:24], fifo_outb, fifo_b
    );
    ntt_fifo_piso #(.DEPTH(5))  PISO_C (
        clk, en, piso_enc, data_in, new_value[2*24+:24], fifo_outc, fifo_c
    );
    ntt_fifo_piso #(.DEPTH(7))  PISO_D (
        clk, en, piso_end, data_in, new_value[3*24+:24], fifo_outd, fifo_d
    );
    
    always @(*) begin
        piso_ena = 0;
        piso_enb = 0;
        piso_enc = 0;
        piso_end = 0;
        data_out = 0;
    
        if (en) begin
            case(mode)
            FORWARD_NTT_MODE: begin
                // Use PISO to write
                case(count)
                0: begin
                    piso_end = 1;
                end
                1: begin
                    piso_enb = 1;
                end
                2: begin
                    piso_enc = 1;
                end
                3: begin
                    piso_ena = 1;
                end
                endcase
                data_out = {fifo_a, fifo_b, fifo_c, fifo_d};
            end
            INVERSE_NTT_MODE: begin
                case(count)
                0: begin
                    data_out = fifo_outa;
                end
                2: begin
                    data_out = fifo_outb;
                end
                1: begin
                    data_out = fifo_outc;
                end
                3: begin
                    data_out = fifo_outd;
                end
                endcase
            end
            endcase
        end
    end
    
    always @(posedge clk) begin
        if (rst)
            count <= 0;
        else if (en)
            count <= count + 1;
    
    end
    
    
endmodule
