`timescale 1ns / 1ps
`define P 10

/*
Author: Luke Beckwith
Affilition: George Mason University
*/


module tb_keygen_top;
    reg clk = 1,  rst = 0, start = 0;
    reg [2:0] sec_lvl = 2;
      
    localparam  NUM_TV = 100;

      
    reg [1:0] mode = 0;
      
    reg valid_i,  ready_o;
    wire ready_i, valid_o;
    reg  [63:0] data_i;  
    wire [63:0] data_o;
    
    combined_top DUT (
        clk,
        rst,
        start,
        mode,
        sec_lvl,
        valid_i,
        ready_i,
        data_i,
        valid_o,
        ready_o,
        data_o
    );
  
    reg [255:0] seed [NUM_TV-1:0];
    reg [0:96*8*4-1] s1_2     [NUM_TV-1:0];
    reg [0:96*8*4-1] s2_2     [NUM_TV-1:0];
    reg [0:416*8*4-1] t0_2     [NUM_TV-1:0];
    reg [0:320*8*4-1] t1_2     [NUM_TV-1:0];
    reg [0:255] k_2     [NUM_TV-1:0];
    reg [0:255] rho_2   [NUM_TV-1:0];
    reg [0:255] tr_2    [NUM_TV-1:0];
    
    reg [0:128/2*5*16-1] s1_3  [NUM_TV-1:0];
    reg [0:128/2*6*16-1] s2_3  [NUM_TV-1:0];
    reg [0:255]          k_3   [NUM_TV-1:0];
    reg [0:255]          rho_3 [NUM_TV-1:0];
    reg [0:19967]        t0_3  [NUM_TV-1:0];
    reg [0:15359]        t1_3  [NUM_TV-1:0];
    reg [0:255]          tr_3  [NUM_TV-1:0];
   
    reg [0:96*2*7*4-1]   s1_5  [NUM_TV-1:0];
    reg [0:96*2*8*4-1]   s2_5  [NUM_TV-1:0];
    reg [0:255]          k_5   [NUM_TV-1:0];
    reg [0:255]          rho_5 [NUM_TV-1:0];
    reg [0:26624-1]      t0_5  [NUM_TV-1:0];
    reg [0:20480-1]      t1_5  [NUM_TV-1:0];
    reg [0:255]          tr_5  [NUM_TV-1:0];
    
    reg [9:0]   ctr, c;

    integer start_time;
  
    // add unload for: rho, t1, t0, and tr
    localparam
        S_INIT = 4'd0,
        S_START = 4'd1,
        S_Z     = 4'd2,
        S_RHO   = 4'd3,
        S_K     = 4'd4,
        S_S1    = 4'd5,
        S_S2    = 4'd6,
        S_T1    = 4'd7,
        S_T0    = 4'd8,
        S_TR    = 4'd9,
        S_STALL = 4'd14,
        S_STOP  = 4'd15;
    
     reg [3:0] state = 0;    
  
    initial begin
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/z_2.txt",  seed);
    
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/s1_2.txt",  s1_2);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/s2_2.txt",  s2_2);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/t0_2.txt",   t0_2);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/t1_2.txt",  t1_2);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/k_2.txt",   k_2);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/rho_2.txt", rho_2);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/tr_2.txt",  tr_2);
        
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/s1_3.txt",  s1_3);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/s2_3.txt",  s2_3);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/t0_3.txt",   t0_3);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/t1_3.txt",  t1_3);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/k_3.txt",   k_3);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/rho_3.txt", rho_3);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/tr_3.txt",  tr_3);
        
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/s1_5.txt",  s1_5);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/s2_5.txt",  s2_5);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/t0_5.txt",   t0_5);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/t1_5.txt",  t1_5);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/k_5.txt",   k_5);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/rho_5.txt", rho_5);
        $readmemh("D:/programming/0_GMU/Dilithium_HighPerf/test_vectors/tr_5.txt",  tr_5);
        
        valid_i = 0;
        ready_o = 0;
        data_i  = 0;
        ctr     = 0; 
        c       = 0;
    end
  

    always @(posedge clk) begin
        rst     <= 0;
        valid_i <= 0;
        start   <= 0;
        ready_o <= 0;
        
        case(sec_lvl)
        2: begin
            case(state)
            S_INIT: begin
                start_time <= $time;
                rst <= 1;
                ctr <= ctr + 1;
                data_i <= seed[c][255 : 192];
                if (ctr == 3) begin
                    ctr <= 0;
                    state <= S_START;
                end
            end
            S_START: begin
                start <= 1;
                state <= S_Z;
            end
            S_Z: begin
                valid_i <= (!ready_i) ? 1 : 0;
               
                if (ready_i) begin
                    ctr <= ctr + 1;
                    valid_i <= 1;
                    if (ctr == 0) begin
                        data_i <= seed[c][191 : 128];
                    end else if (ctr == 1) begin
                        data_i <= seed[c][127 : 64];
                    end else if (ctr == 2) begin
                        data_i <= seed[c][63:0];
                    end else begin
                        ctr <= 0;
                        state <= S_RHO;
                    end
                end 
            end
            S_STALL: begin
                ready_o <= 1;
            end
            S_RHO: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== rho_2[c][ctr*64+:64])
                        $display("[Rho, %d] Error: Expected %h, received %h", ctr, rho_2[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_K;
//                        $display("TB: Done Rho");
                    end
                end
            end        
            S_K: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== k_2[c][ctr*64+:64])
                        $display("[K, %d] Error: Expected %h, received %h", ctr, k_2[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_S1;
//                        $display("TB: Done K");
                    end
                end
            end
            S_S1: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== s1_2[c][ctr*64+:64])
                        $display("[S1, %d] Error: Expected %h, received %h", ctr, s1_2[c][ctr*64+:64], data_o); 
    
                    ctr <= ctr + 1;
                    
                    if (ctr == 47) begin
                        ctr <= 0;
                        state <= S_S2;
//                        $display("TB: Done S1");
                    end
                end
            end
            S_S2: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== s2_2[c][ctr*64+:64])
                        $display("[S2, %d] Error: Expected %h, received %h", ctr, s2_2[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 47) begin
                        ctr <= 0;
                        state <= S_T1;
//                        $display("TB: Done S2");
                    end
                end
            end
            S_T1: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== t1_2[c][ctr*64+:64])
                        $display("[T1, %d] Error: Expected %h, received %h", ctr, t1_2[c][ctr*64+:64], data_o); 
//                    else 
//                        $display("[T1, %d] Correct: Expected %h, received %h", ctr, t1_2[c][ctr*64+:64], data_o);
                    ctr <= ctr + 1;
                    
                    if (ctr == 4*320/8-1) begin
                        ctr <= 0;
                        state <= S_T0;
//                        $display("TB: Done T1");
                    end
                end
            end
            S_T0: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== t0_2[c][ctr*64+:64])
                        $display("[T0, %d] Error: Expected %h, received %h", ctr, t0_2[c][ctr*64+:64], data_o); 
//                    else
//                        $display("[T0, %d] Correct: Expected %h, received %h", ctr, t0_2[c][ctr*64+:64], data_o); 
                    ctr <= ctr + 1;
                    
                    if (ctr == 4*416/8-1) begin
                        ctr <= 0;
                        state <= S_TR;
//                        $display("TB: Done T0");
                    end
                end
            end
            S_TR: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== tr_2[c][ctr*64+:64])
                        $display("[TR, %d] Error: Expected %h, received %h", ctr, tr_2[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_STOP;
//                        $display("TB: Done TR");
                    end
                end
            end
            S_STOP: begin
                ready_o <= 1;
                c       <= c + 1;
                state <= S_INIT;

                $display("KG2[%d] completed in %d clock cycles", c, ($time-start_time)/10);

                if (c == NUM_TV-1) begin
                    c <= 0;
                    sec_lvl <= 3;
                    $display ("Moving to KG3");
                    //$finish;
                end
            end
            endcase
        end
        3: begin
            case(state)
            S_INIT: begin
                start_time = $time;
            
                rst <= 1;
                ctr <= ctr + 1;
                data_i <= seed[c][255 : 192];
                if (ctr == 3) begin
                    ctr <= 0;
                    state <= S_START;
                end
            end
            S_START: begin
                start <= 1;
                state <= S_Z;
            end
            S_Z: begin
                valid_i <= (!ready_i) ? 1 : 0;
               
                if (ready_i) begin
                    ctr <= ctr + 1;
                    valid_i <= 1;
                    if (ctr == 0) begin
                        data_i <= seed[c][191 : 128];
                    end else if (ctr == 1) begin
                        data_i <= seed[c][127 : 64];
                    end else if (ctr == 2) begin
                        data_i <= seed[c][63:0];
                    end else begin
                        ctr <= 0;
                        state <= S_RHO;
                    end
                end 
            end
            S_STALL: begin
                ready_o <= 1;
            end
            S_RHO: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== rho_3[c][ctr*64+:64])
                        $display("[Rho, %d] Error: Expected %h, received %h", ctr, rho_3[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_K;
                        // $display("TB: Done Rho");
                    end
                end
            end        
            S_K: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== k_3[c][ctr*64+:64])
                        $display("[K, %d] Error: Expected %h, received %h", ctr, k_3[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_S1;
                        // $display("TB: Done K");
                    end
                end
            end
            S_S1: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== s1_3[c][ctr*64+:64])
                        $display("[S1, %d] Error: Expected %h, received %h", ctr, s1_3[c][ctr*64+:64], data_o); 
    
                    ctr <= ctr + 1;
                    
                    if (ctr == 128/2*5*16/64-1) begin
                        ctr <= 0;
                        state <= S_S2;
                        // $display("TB: Done S1");
                    end
                end
            end
            S_S2: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== s2_3[c][ctr*64+:64])
                        $display("[S2, %d] Error: Expected %h, received %h", ctr, s2_3[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 128/2*6*16/64-1) begin
                        ctr <= 0;
                        state <= S_T1;
                        // $display("TB: Done S2");
                    end
                end
            end
            S_T1: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== t1_3[c][ctr*64+:64])
                        $display("[T1, %d] Error: Expected %h, received %h", ctr, t1_3[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 15360/64-1) begin
                        ctr <= 0;
                        state <= S_T0;
                        // $display("TB: Done T1");
                    end
                end
            end
            S_T0: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== t0_3[c][ctr*64+:64])
                        $display("[T0, %d] Error: Expected %h, received %h", ctr, t0_3[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 19968/64-1) begin
                        ctr <= 0;
                        state <= S_TR;
                        // $display("TB: Done T0");
                    end
                end
            end
            S_TR: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== tr_3[c][ctr*64+:64])
                        $display("[TR, %d] Error: Expected %h, received %h", ctr, tr_3[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_STOP;
                        // $display("TB: Done TR");
                        // $display($time/10);
                    end
                end
            end
            S_STOP: begin
                ready_o <= 1;
                c       <= c + 1;
                state <= S_INIT;

                $display("KG3[%d] completed in %d clock cycles", c, ($time-start_time)/10);

                if (c == NUM_TV-1) begin
                    c <= 0;
                    sec_lvl <= 5;
                    $display ("Moving to KG5");
//                    $finish;
                end
            end
            endcase
        end
        5: begin
            case(state)
            S_INIT: begin
                start_time = $time;
                rst <= 1;
                ctr <= ctr + 1;
                data_i <= seed[c][255 : 192];
                if (ctr == 3) begin
                    ctr <= 0;
                    state <= S_START;
                end
            end
            S_START: begin
                start <= 1;
                state <= S_Z;
            end
            S_Z: begin
                valid_i <= (!ready_i) ? 1 : 0;
               
                if (ready_i) begin
                    ctr <= ctr + 1;
                    valid_i <= 1;
                    if (ctr == 0) begin
                        data_i <= seed[c][191 : 128];
                    end else if (ctr == 1) begin
                        data_i <= seed[c][127 : 64];
                    end else if (ctr == 2) begin
                        data_i <= seed[c][63:0];
                    end else begin
                        ctr <= 0;
                        state <= S_RHO;
                    end
                end 
            end
            S_STALL: begin
                ready_o <= 1;
            end
            S_RHO: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== rho_5[c][ctr*64+:64])
                        $display("[Rho, %d] Error: Expected %h, received %h", ctr, rho_5[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_K;
                        // $display("TB: Done Rho");
                    end
                end
            end        
            S_K: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== k_5[c][ctr*64+:64])
                        $display("[K, %d] Error: Expected %h, received %h", ctr, k_5[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_S1;
                        // $display("TB: Done K");
                    end
                end
            end
            S_S1: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== s1_5[c][ctr*64+:64])
                        $display("[S1, %d] Error: Expected %h, received %h", ctr, s1_5[c][ctr*64+:64], data_o); 
    
                    ctr <= ctr + 1;
                    
                    if (ctr == 96/2*7*16/64-1) begin
                        ctr <= 0;
                        state <= S_S2;
                        // $display("TB: Done S1");
                    end
                end
            end
            S_S2: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== s2_5[c][ctr*64+:64])
                        $display("[S2, %d] Error: Expected %h, received %h", ctr, s2_5[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 96/2*8*16/64-1) begin
                        ctr <= 0;
                        state <= S_T1;
                        // $display("TB: Done S2");
                    end
                end
            end
            S_T1: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== t1_5[c][ctr*64+:64])
                        $display("[T1, %d] Error: Expected %h, received %h", ctr, t1_5[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 20480/64-1) begin
                        ctr <= 0;
                        state <= S_T0;
                        // $display("TB: Done T1");
                    end
                end
            end
            S_T0: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== t0_5[c][ctr*64+:64])
                        $display("[T0, %d] Error: Expected %h, received %h", ctr, t0_5[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 26624/64-1) begin
                        ctr <= 0;
                        state <= S_TR;
                        // $display("TB: Done T0");
                    end
                end
            end
            S_TR: begin
                ready_o <= 1;
                if (valid_o) begin
                    if (data_o !== tr_5[c][ctr*64+:64])
                        $display("[TR, %d] Error: Expected %h, received %h", ctr, tr_5[c][ctr*64+:64], data_o); 
                
                    ctr <= ctr + 1;
                    
                    if (ctr == 3) begin
                        ctr <= 0;
                        state <= S_STOP;
                        // $display("TB: Done TR");
                        // $display($time/10);
                    end
                end
            end
            S_STOP: begin
                ready_o <= 1;
                c       <= c + 1;
                state <= S_INIT;

                $display("KG5[%d] completed in %d clock cycles", c, ($time-start_time)/10);

                if (c == NUM_TV-1) begin
                    c <= 0;
                    $display ("Testbench done.");
                    $finish;
                end
            end
            endcase
        end
        endcase
  
    end
      
  
    always #(`P/2) clk = ~clk;
  

endmodule
`undef P