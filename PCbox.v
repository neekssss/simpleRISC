module PCbox(datapath_out,PC,zonk,im8,op,opcode,cond,PCout);
    input [8:0] datapath_out;
    input [8:0] PC;
    input [2:0] zonk;
    input [8:0] im8;
    input [1:0] op;
    input [2:0] opcode, cond;
    output reg [8:0] PCout;
    wire [8:0] temp; 

    assign temp = PC; // Temp value incase PC is accedentaly modified

    always @(*)begin // Controls PC -> new_PC values For Tables 1, and 2 of lab 8
        casex({opcode,op,cond}) 
        8'b00100_000 : PCout = temp  + im8; // B command
        8'b00100_001 : begin if (zonk[0] == 1'b1) PCout = temp  + im8; else PCout = temp ; end // BEQ command
        8'b00100_010 : begin if (zonk[0] == 1'b0) PCout = temp  + im8; else PCout = temp ; end // BNE command
        8'b00100_011 : begin if (zonk[1] != zonk[2]) PCout = temp +  im8; else PCout = temp ; end // BLT command
        8'b00100_100 : begin if ((zonk[1] != zonk[2])|(zonk[0] == 1'b1)) PCout <= temp  + im8; else PCout = temp ; end // BLE command
        8'b01011_xxx : PCout <= temp + im8; // BL command
        8'b01000_xxx : PCout <= datapath_out; // BX command
        default: PCout = temp; // Default value to avoid latches
        endcase 
    end

endmodule 
