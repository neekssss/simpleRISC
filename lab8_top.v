module lab8_top(KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, CLOCK_50);
    input [3:0] KEY;
    input [9:0] SW;
    input CLOCK_50;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    wire [8:0] mem_addr;
    wire [15:0] write_data, read_data, din, dout;
    wire [1:0] mem_cmd;
    wire [8:0] addrm0, addrm1; // feed into addr select MUX from Data Address Reg and PC, respectivley
    reg [7:0] temp;
    wire msel, mcmd; // outputs to equality comparators 8 and 9, respectivley
    wire ando; // fed into tri-state driver via and of msel and mcmd
    wire wcalc; // feeds into AND gate which powers write in RAM
    wire swc, ledc; // switch and LED tri-state control wires, respectivley

    // primary module instantiation
    RAM #(16,8) MEM(CLOCK_50, mem_addr[7:0], mem_addr[7:0], write, write_data, dout); // memory module instantiation
    cpu CPU(CLOCK_50, ~KEY[1], read_data, write_data, N, V, Z, mem_cmd, mem_addr, LEDR[8]); // cpu module instantiation

    assign msel  = (mem_addr[8] == 1'b0) ? 1'b1 : 1'b0; // fed into AND gate to determine ando (8)
    assign mcmd  = (mem_cmd == 2'b01) ? 1'b1 : 1'b0; // MREAD
    assign wcalc = (mem_cmd == 2'b10) ? 1'b1 : 1'b0; // MWRITE
    assign write = (msel & wcalc) ? 1'b1 : 1'b0; // fed into write
    assign ando  = (msel & mcmd) ? 1'b1 : 1'b0; // fed into tri-state driver (7)
    assign read_data = (ando == 1'b1) ? dout : ((swc == 1'b1) ? {8'b0, SW[7:0]} : 16'bz); // tri-state logic

    indevice id(mem_cmd, mem_addr, swc); // Switch (input) controls
    outdevice od(mem_cmd, mem_addr, ledc); // LED (output) controls

    always@(posedge CLOCK_50) begin // LED output control
      if(ledc == 1'b1) begin
        temp = write_data[7:0];
      end
    end

    assign LEDR[7:0] = temp; // LED output control
endmodule

module RAM(clk, read_address, write_address, write, din, dout); // Taken from Slide-Set 7 as per Lab 7 document
  parameter data_width = 32; 
  parameter addr_width = 4;
  parameter filename = "data.txt";

  input clk;
  input [addr_width-1:0] read_address, write_address;
  input write;
  input [data_width-1:0] din;
  output [data_width-1:0] dout;
  reg [data_width-1:0] dout;

  reg [data_width-1:0] mem [2**addr_width-1:0];

  initial $readmemb(filename, mem);

  always @ (posedge clk) begin
    if (write)
      mem[write_address] <= din;
    dout <= mem[read_address]; // dout doesn't get din in this clock cycle 
                               // (this is due to Verilog non-blocking assignment "<=")
  end 
endmodule

module indevice(mem_cmd, mem_addr, out); // left block
  input [1:0] mem_cmd;
  input [8:0] mem_addr;
  output out;

  assign out = ((mem_cmd == 2'b01) & (mem_addr == 9'h140)) ? 1'b1 : 1'b0; // true if: read && mem_addr
endmodule  

module outdevice(mem_cmd, mem_addr, out); // right block
  input [1:0] mem_cmd;
  input [8:0] mem_addr;
  output out;
  
  assign out = ((mem_cmd == 2'b10) & (mem_addr == 9'h100)) ? 1'b1 : 1'b0; // true if: write && mem_addr
endmodule
