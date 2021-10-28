`timescale 1ns / 1ps

module norm_check(
    input [2:0] sec_lvl,
    input [1:0] mode,
    input validi,
    input [95:0] di,
    output reg rej
    );
    
    reg [3:0] rej_lane;
    integer i;
    
    localparam
        G2_SUB_BETA = 3'd0,
        G1_SUB_BETA = 3'd1,
        G2          = 3'd2;
    
    localparam
        Q            = 23'd8380417,
        GAMMA1_LVL2  = 23'd131072,
        GAMMA1_LVL35 = 23'd524288,
        GAMMA2_LVL2  = 23'd95232,
        GAMMA2_LVL35 = 23'd261888,
        BETA2        = 23'd78,
        BETA3        = 23'd196,
        BETA5        = 23'd120;
    
    reg [22:0] GAMMA1;
    reg [22:0] GAMMA2;
    reg [22:0] BETA;
    
    reg [22:0] COND_UPPER, COND_LOWER;
    
    always @(*) begin
        
        case(sec_lvl)
        2: begin
            GAMMA1 = GAMMA1_LVL2;
            GAMMA2 = GAMMA2_LVL2;
        end
        default: begin
            GAMMA1 = GAMMA1_LVL35;
            GAMMA2 = GAMMA2_LVL35;
        end
        endcase
    
        case(sec_lvl)
        2: begin
            BETA = BETA2;
        end
        3: begin
            BETA = BETA3;
        end
        default: begin
            BETA = BETA5;
        end
        endcase
        
        case(mode)
        G2_SUB_BETA: begin
            COND_UPPER = GAMMA2 - BETA;
            COND_LOWER = Q - (GAMMA2 - BETA);
        end
        G1_SUB_BETA: begin
            COND_UPPER = GAMMA1 - BETA;
            COND_LOWER = Q - (GAMMA1 - BETA);
        end
        default: begin //G2
            COND_UPPER = GAMMA2;
            COND_LOWER = Q - (GAMMA2);
        end
        endcase
        
        rej_lane = 0;
        for (i = 0; i < 4; i = i + 1) begin
            if (di[i*24+:24] >= COND_UPPER && di[i*24+:24] <= COND_LOWER)
                rej_lane[i] = validi;
        end
    
        rej = |rej_lane;
    
    end
    
endmodule
