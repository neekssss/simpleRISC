// cpu cp((clk, reset, in, mdata, mem_cmd, addr_sel, load_pc, reset_pc, load_addr, datapath_out); // NEW cpu module instantiation (AS PER FIGURE 2)
module cpu(clk, reset, mdata, out, N, V, Z, mem_cmd, mem_addr,halt);
    input clk, reset;
    input [15:0] mdata;
    output [15:0] out;
    output N, V, Z;
    output [1:0] mem_cmd;
    output [8:0] mem_addr;
    output halt;

    wire [20:0] mainout;
    wire [2:0] opcode, writenum, readnum;
    wire [1:0] op, shift, ALUop;
    wire [15:0] sximm8, sximm5, regout;
    wire load_ir;
    wire [2:0] zonk;
    wire [8:0] addrm0, PC, next_pc, new_PC;
    wire [15:0] bonk_pc;
    // Z_out assignments
    assign Z = zonk[0]; // original status
    assign N = zonk[1]; // negative status
    assign V = zonk[2]; // overflow status
    assign mem_cmd = mainout[16:15];

    vDFFE #(16) ireg(clk, mainout[20], mdata, regout); // instruction register
    InDecoder id(regout, mainout[13:11], opcode, op, writenum, readnum, shift, ALUop, sximm8, sximm5); // instruction decoder
    state1 FSM( reset, clk, opcode, op, mainout,halt); // state machine
    datapath DP(bonk_pc,(PC-2'b11),sximm8, sximm5, mainout[10:7], writenum, mainout[0], readnum, clk, mainout[1], mainout[2], mainout[3], shift, mainout[5], mainout[6], ALUop, mainout[4], zonk, out, mdata);
    // PC and Data Address logic (Lab 7)

    PCbox PCsel(bonk_pc[8:0],PC,zonk,sximm8[8:0],op,opcode,regout[10:8],new_PC); // added for lab 8

    MUX29 pcSel((new_PC+1'b1), 9'b000000000, mainout[14], next_pc); // PC Select MUX (Might need to change first input)
    vDFFE #(9) progC(clk, mainout[19], next_pc, PC); // Program Counter Register
    vDFFE #(9) dataA(clk, mainout[18], out[8:0], addrm0); // Data Address Register
    MUX29 addrSel(addrm0,PC, mainout[17], mem_addr); // Address Select MUX

endmodule

module InDecoder(in, nsel, opcode, op, writenum, readnum, shift, ALUop, sximm8, sximm5); // instruction decoder as in lab6 handout
    input [15:0] in;
    input [2:0] nsel; // 1 hot select to pick betweer Rn, Rd, Rm
    output [2:0] opcode, writenum;
    output [1:0] op;
    output [15:0] sximm8, sximm5;
    output [1:0] shift, ALUop;
    output reg [2:0] readnum;

    assign shift = in[4:3]; // shift values to be passed on to datapath
    assign ALUop = in[12:11]; // ALUop values to be passed on to datapath
    assign opcode = in[15:13]; // feeds into state machine
    assign op = in [12:11]; // feeds into state machine
    assign writenum = readnum; // Equating writenum and readnum

    SignExtend #(8) sx8(in[7:0], sximm8); // sign extention for sximm8
    SignExtend sx5(in[4:0], sximm5); // sign extention for sximm5

    always @(*) begin // MUX to select Rn, Rd, Rm
        case (nsel)
            3'b001: readnum = in[2:0]; // Rm
            3'b010: readnum = in[7:5]; // Rd
            3'b100: readnum = in[10:8]; // Rn
            default: readnum = 3'bxxx; // default value to avoid latches
        endcase
    end
endmodule

module SignExtend(inx, outx); // sign extend function used for sximm8 & sximm5 (Currently only for 5 or 8 bits)
    parameter n = 5;
    input [n-1:0] inx;
    output reg [15:0] outx;
    
    always @(*) begin // Adds enough 1's or 0's to make inx 16 bits based on MSB
        if (n == 5) begin
            if (inx[4] == 0) begin
                outx = {11'b00000000000,inx}; // if MSB == 0 for sximm5
            end else begin
                outx = {11'b11111111111,inx}; // if MSB == 1 for sximm5
            end
        end else begin
            if (inx[7] == 0) begin
                outx = {8'b00000000,inx}; // if MSB == 0 for sximm8
            end else begin
                outx = {8'b11111111,inx}; // if MSB == 1 for sximm8
            end
        end
    end
endmodule


//Encoding for mainout
     //20 load_ir
     //19 load_pc
     //18 load_addr
     //17 addr_sel
     //16:15 mem_cmd  01read/10write
     //14 reset_pc 
     //11:13 nsel
     //10:7  vsel
     //6 bsel
     //5 asel
     //4 loads
     //3 loadc
     //2 loadb
     //1 loada
     //0 write
module state1(reset, clk, opcode, op, mainout,halt); 
 // module I/O
`define reset               5'b00000  // RESET State
`define IF1                 5'b00001  // IF1 State
`define IF2                 5'b00010  // IF2 State
`define updatePC            5'b00011  // PC update State

`define decode              5'b00100  // DECODING State
`define read_n_a            5'b00101 // Load RN into RegA
`define read_m_b            5'b00110 // Load RM into RegB

`define write_d_c           5'b00111 // Write Output into RegD
`define write_n_sx          5'b01000// Write sximm8 Into Register RN

`define calculate_nb_na     5'b01001 // Send RegA and RegB Through ALUop
`define calculate_nb_a      5'b01010 // Send Reg into Shifter
`define calculate_b_na      5'b01011
`define status              5'b01100 // Output Status Values Z, V, N

`define load_mem_read       5'b01101 // Loads memory to be read
`define write_d_mdata       5'b01110 // writes Rd
`define read_d_b            5'b01111 // Loads Rd into RegB (In Datapath)
`define load_mem_write      5'b10000 // Loads for memory write
`define DAR                 5'b10001
`define write_n_pc          5'b10010 // writes PC into Rn
`define do_nothing          5'b10011 // Extra clock cycle for safety

    // Module I/O
    input reset, clk;
    input [2:0] opcode;
    input [1:0] op;
    output halt;
    output reg [20:0] mainout; 
    reg [4:0] next_state, state; // States


    always @(posedge clk) begin // reset block, handles reset value and returning to wait as a result
        if (reset == 1'b1) begin
            state = `reset;
    end else begin
            state = next_state;
        end
    end
    
    assign halt = ({opcode,op} != 5'b11100)? 1'b0 : (state == `decode)? 1'b1 : 1'b0; // HALT for AUTOGRADER
    
always@(*) begin
  case(state)
    `reset          :next_state = `IF1; // Reset State
    `IF1            :next_state = `IF2;
    `IF2            :next_state = `updatePC; 

    `updatePC       :next_state = `decode;

    `decode         :begin if ({opcode,op}== 5'b10111) next_state = `read_m_b;                                  //6.a

                     else  if ({opcode,op} == 5'b01011) next_state =  `write_n_pc;                              //BL.a  
                     else  if ({opcode,op} == 5'b01000) next_state =  `read_d_b;  

                     else  if ({opcode,op}== 5'b11100) next_state = `decode;                                    //HALT
                     else  if ({opcode,op}== 5'b11000) next_state = `read_m_b;                                  //2.a
                     else  if ({opcode,op}== 5'b11010) next_state = `write_n_sx; 
                     else  if ({opcode,op} == 5'b00100) next_state = `do_nothing;                                //1.a
                     else   next_state = `read_n_a; end                                                         //3.a/5.a/4.a/LDR.a/STR.a

    `read_n_a       :next_state =  (opcode == 3'b011)? `calculate_b_na : (opcode == 3'b100)? `calculate_b_na:  `read_m_b;                  //LDR.b,STR.b  //3.b //5.b //4.b
    `read_m_b       :next_state =  (opcode ==   5'b110  )? `calculate_nb_a : `calculate_nb_na;                  //2.b/nb_a     //3.c/5.c/4.c/6.b/nb_nb 
    `calculate_b_na :next_state =  `DAR;                           
    `calculate_nb_a :next_state =  ({opcode,op} == 5'b10000    )? `load_mem_write  : `write_d_c;                 //STR.e        //2.c
    `calculate_nb_na:next_state =  ({opcode,op} == 5'b10101    )? `status         : `write_d_c;                 //4.d          // 3.d/ 5.d/ 6.c 
    `DAR            :next_state =  ({opcode,op} ==   5'b01100  )? `load_mem_read : `read_d_b;                   //LDR.c        //STR.c

    `write_n_pc     :next_state = `IF1; 
    
    `load_mem_write :next_state = `IF1;                                                                         //STR.f
    `load_mem_read  :next_state = `write_d_mdata;                                                               //LDR.c
    `write_d_mdata  :next_state = `IF1;                                                                         //LDR.d
    `read_d_b       :next_state = ({opcode,op} == 5'b01000)? `IF1 :`calculate_nb_a;                                                             //STR.d
    `write_n_sx     :next_state = `IF1;                                                                         //1.b 
    `write_d_c      :next_state = `IF1;                                                                         //2.d/3.e/5.e/6.d  
    `status         :next_state = `IF1;                                                                         //4.e 
    `do_nothing     :next_state = `IF1;
     default        :next_state = `reset;
  endcase
end 

  always @(*)begin
   case(state) 
      `reset           :mainout = 21'b010_0_00_1_000_0000_00_0000_0;  // reset on,
      `IF1             :mainout = 21'b000_1_01_0_000_0000_00_0000_0;  // 
      `IF2             :mainout = 21'b100_1_01_0_000_0000_00_0000_0;  // 
      `updatePC        :mainout = 21'b010_0_00_0_000_0000_00_0000_0;  // update PC

      `read_n_a        :mainout = 21'b000_0_00_0_100_0000_00_0001_0;  // read Rn into A
      `read_m_b        :mainout = 21'b000_0_00_0_001_0000_00_0010_0;  // read Rm into B

      `calculate_b_na  :mainout = 21'b000_0_00_0_000_0000_10_0100_0;  // Send reg through Shifter
      `calculate_nb_a  :mainout = 21'b000_0_00_0_000_0000_01_0100_0;  // Send reg through Shifter
      `calculate_nb_na :mainout = 21'b000_0_00_0_000_0000_00_0100_0;  // ALUop values in RegA and RegB

      `DAR             :mainout = 21'b001_0_00_0_000_0000_00_0000_0;  

      `load_mem_read   :mainout = 21'b000_0_01_0_000_0000_00_0000_0;  //load into memory for reading
      `load_mem_write  :mainout = 21'b000_0_10_0_000_0000_00_0000_0; //load into memory for writing
      `write_d_mdata   :mainout = 21'b000_0_01_0_010_0001_00_0000_1;  //write mdata into Rd
      `read_d_b        :mainout = ({opcode,op} == 5'b01000)?21'b010_1_01_0_010_0000_00_0010_0 : 21'b000_0_00_0_010_0000_00_0010_0;  //read Rd into Bin

      `write_n_pc      :mainout = 21'b000_0_00_0_100_0100_00_0000_1;

      `write_d_c       :mainout = 21'b000_0_00_0_010_1000_00_0000_1;  //write C using vsel to Rd
      `write_n_sx      :mainout = 21'b000_0_00_0_100_0010_00_0000_1;  //write sximm8 using vsel to Rn
      `status          :mainout = 21'b000_0_00_0_000_0000_00_1000_0;  //Output status values
       default         :mainout = 21'b000_0_00_0_000_0000_00_0000_0;  //default for waiting state, decode state, and any other ones for the porpose of debugging
   endcase 
end
endmodule

module MUX29(in0, in1, s, b); // 2 option selection multiplexer
    input [8:0] in0, in1;  // inputs
    input s; // binary select
    output reg [8:0] b; // output of multiplexer

    always @(*) begin // sets 'b' to desired register based on binary input 's'
        case (s) // case statement to deicide witch input to give to outbut 'b'
            1'b0: b <= in0; // position 2 select
            1'b1: b <= in1; // position 1 select
            default: b <= 9'bxxxxxxxxx; // default value to avoid latches
        endcase
     end
endmodule
