`timescale 1ns / 1ps
module dual_port_ram #(parameter WIDTH=96, LENGTH=1024, INIT_FILE="") (clka,clkb,ena,enb,wea,web,addra,addrb,dia,dib,doa,dob);
    input clka,clkb,ena,enb,wea,web;
    input [$clog2(LENGTH)-1:0] addra,addrb;
    input [WIDTH-1:0] dia,dib;
    output [WIDTH-1:0] doa,dob;
    reg[WIDTH-1:0] ram [LENGTH-1:0];
    reg[WIDTH-1:0] doa,dob;
    
    always @(posedge clka) begin if (ena)
        begin
            if (wea)
                ram[addra] <= dia;
                doa <= ram[addra];
            end
        end
        always @(posedge clkb) begin if (enb)
        begin
            if (web)
                ram[addrb] <= dib;
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