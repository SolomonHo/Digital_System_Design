`timescale 1ns/10ps
`define CYCLE  10
`define HCYCLE  5

module register_file_tb;
    // port declaration for design-under-test
    reg Clk, WEN;
    reg  [2:0] RW, RX, RY;
    reg  [7:0] busW;
    wire [7:0] busX, busY, busX_gold, busY_gold;

    register_gold rg(
        Clk  ,
        WEN  ,
        RW   ,
        busW ,
        RX   ,
        RY   ,
        busX_gold ,
        busY_gold
    );
    
    // instantiate the design-under-test
    register_file rf(
        Clk  ,
        WEN  ,
        RW   ,
        busW ,
        RX   ,
        RY   ,
        busX ,
        busY
    );

    // write your test pattern here
    always#(`HCYCLE) Clk = ~Clk;

    // initial begin
    //    $fsdbDumpfile("alu_assign.fsdb");
    //    $fsdbDumpvars(0, register_file_tb, "+mda");
    // end

    initial begin
        Clk = 0;
    end

    integer test_count, loop_count, error_count;
    reg start_flag;

    initial begin
        #(2*`CYCLE);
        loop_count = 1000;
        RX = 0;
        RY = 0;
        RW = 0;
        busW = 0;
        WEN = 0;
        error_count = 0;
        start_flag = 0;


        for (test_count=0; test_count<8; test_count=test_count+1) begin
            @(posedge Clk);
            #(0.3*`CYCLE);
            RW = test_count;
            busW = 0;
            WEN = 1;
        end
        start_flag = 1;

        for (test_count=0; test_count<loop_count; test_count=test_count+1) begin
            @(posedge Clk);
            #(0.3*`CYCLE);
            RX = {$random} % 8;
            RY = {$random} % 8;
            RW = {$random} % 8;
            busW = {$random} % 256;
            WEN = {$random} % 2;
        end
        if (error_count == 0) begin
            $display("****************************        /|__/|");
            $display("**                        **      / O,O  |");
            $display("**   Congratulations !!   **    /_____   |");
            $display("** All Patterns Passed!!  **   /^ ^ ^ \\  |");
            $display("**                        **  |^ ^ ^ ^ |w|");
            $display("****************************   \\m___m__|_|");
        end
        else begin
            $display("Error Count = %d", error_count);
            $display("**********FAILED**********");
        end
        $finish;

    end

    always@(posedge Clk) begin
        if (start_flag)begin
            #(0.1*`CYCLE);
            if (busX !== busX_gold) begin
                error_count = error_count + 1;
            end
            if (busY !== busY_gold) begin
                error_count = error_count + 1;
            end

            #(0.5*`CYCLE);
            if (busX !== busX_gold) begin
                error_count = error_count + 1;
            end
            if (busY !== busY_gold) begin
                error_count = error_count + 1;
            end
        end
    end


endmodule

module register_gold(
    Clk  ,
    WEN  ,
    RW   ,
    busW ,
    RX   ,
    RY   ,
    busX ,
    busY
);

input        Clk, WEN;
input  [2:0] RW, RX, RY;
input  [7:0] busW;
output [7:0] busX, busY;

    reg [7:0] regfile_w [0:7], regfile_r [0:7];
    assign busX = regfile_r[RX];
    assign busY = regfile_r[RY];

    integer i;

    always @(*) begin
        regfile_w[0] = 8'b0;
        for (i=1; i<8; i=i+1) begin
            if (i == RW && WEN) begin
                regfile_w[i] = busW;
            end
            else begin
                regfile_w[i] = regfile_r[i];
            end
        end
    end

    always @(posedge Clk) begin
        regfile_r[0] <= 8'b0;
        for (i=1; i<8; i=i+1) begin
            regfile_r[i] <= regfile_w[i];
        end

    end

endmodule