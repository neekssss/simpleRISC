module pc_tb;
    reg [8:0] PC;
    reg [2:0] zonk;
    reg [8:0] im8;
    reg [1:0] op;
    reg [2:0] opcode, cond;
    wire [8:0] PCout;

    PCbox DUT(PC,zonk,im8,op,opcode,cond,PCout);

    initial begin
        im8 = 9'b00000011;
        PC = 9'b0;
        zonk = 3'b000;
        cond = 3'b000;
        opcode = 3'b011;
        op = 2'b00;
        #2;

        if (PCout == 9'b0) begin
            $display("1 WORKING");
        end

        #2;

        opcode = 3'b001;
        op = 2'b00;

        #2;

        if (PCout == 9'b00000011) begin
            $display("2 WORKING");
        end

        PC = PCout;
        opcode = 3'b001;
        cond = 3'b001;
        op = 2'b00;
        zonk = 3'b001;

        #2;

        if (PCout == 9'b00000110) begin
            $display("3 WORKING");
        end

        #2;

        PC = PCout;
        opcode = 3'b001;
        cond = 3'b010;
        op = 2'b00;
        zonk = 3'b000;

        #2;

        if (PCout == 9'b00001001) begin
            $display("4 WORKING");
        end

        #2;

        $stop;
    end
endmodule