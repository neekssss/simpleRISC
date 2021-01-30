module demo;
    reg [3:0] KEY;
    reg [9:0] SW;
    reg CLOCK_50;
    wire [9:0] LEDR;
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;


    lab8_top DUT(KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, CLOCK_50);

    initial forever begin
        CLOCK_50 = 0; #5;
        CLOCK_50 = 1; #5;
    end

    initial begin
        SW = 9'b0000000011;
        #5;
        KEY[1] = 1;
        #10;
        KEY[1] = 0;
        #10;

/*
        SW = 9'b0000000001;
        #5;
        KEY[1] = 1;
        #10;
        KEY[1] = 0;
        #10; */
        
        $stop;
    end
endmodule