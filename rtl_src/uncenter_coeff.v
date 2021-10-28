`timescale 1ns / 1ps

module uncenter_coeff(
    input [2:0] sec_lvl,
    input [2:0] mode,
    input [22:0] di,
    output reg [22:0] dout
    );
    
    localparam
        Q = 23'd8380417;
        
    localparam
        M_NONE   = 3'd0,
        M_ETA    = 3'd1,
        M_T0     = 3'd2,
        M_T1     = 3'd3,
        M_GAMMA1 = 3'd4;
        
    reg signed [23:0] t0, t1;
    
    reg [3:0] ETA;
    reg [12:0] T;
    reg [19:0] GAMMA1;
    always @(*) begin
        ETA    = (sec_lvl == 3) ? 4 : 2;
        T      = (1 << 13-1);
        GAMMA1 = (sec_lvl == 2) ? (1 << 17) : (1 << 19);
        
        t1 = (di + T - 1) >> 13;
        t0 = di - (t1 << 13);
        
        (*full_case*)
        case({mode})
        M_NONE:   dout = di;
        M_ETA:    dout = (di > ETA)    ? ETA + Q - di    : ETA - di;
        M_T0:     dout = T - t0;
        M_T1:     dout = t1;
        M_GAMMA1: dout = (di > GAMMA1) ? GAMMA1 + Q - di : GAMMA1 - di;
        endcase
    end
    
endmodule
