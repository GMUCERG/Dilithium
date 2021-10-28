`timescale 1ns / 1ps
module dual_port_rom #(parameter WIDTH=96, LENGTH=1024, INIT_FILE="") (clk,en,addra,addrb,doa,dob);
    input clk,en;
    input [$clog2(LENGTH)-1:0] addra,addrb;
    output [WIDTH-1:0] doa,dob;
    (* rom_style = "distributed" *) reg[WIDTH-1:0] ram [LENGTH-1:0];
    reg[WIDTH-1:0] doa,dob;
    
    always @(posedge clk) begin 
        if (en) begin
            doa <= ram[addra];
            dob <= ram[addrb];
        end
    end
    
    
    integer i;
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end else begin
            for (i = 0; i < LENGTH; i = i + 1)
                ram[i] = 0;
        end
    end
    
endmodule