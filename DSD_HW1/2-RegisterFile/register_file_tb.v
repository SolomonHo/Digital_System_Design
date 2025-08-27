`timescale 1ns/10ps
`define CYCLE  10
`define HCYCLE  5

module register_file_tb;
    // port declaration for design-under-test
    reg Clk, WEN;
    reg  [2:0] RW, RX, RY;
    reg  [7:0] busW;
    wire [7:0] busX, busY;

    reg fail;
    
    // instantiate the design-under-test
    register_file rf(
        .Clk(Clk)  ,
        .WEN(WEN)  ,
        .RW(RW)   ,
        .busW(busW) ,
        .RX(RX)   ,
        .RY(RY)   ,
        .busX(busX) ,
        .busY(busY)
    );

    // write your test pattern here
    initial begin
       $fsdbDumpfile("register.fsdb");
       $fsdbDumpvars;
    end

    initial Clk = 0;

    initial begin
        WEN = 1'b0;
        RW = 3'd0;
        RX = 3'd0;
        RY = 3'd0;
        
        #(`HCYCLE);
        WEN = 0; RW = 3'd0; RX = 3'd0; RY = 3'd1; busW = 8'd0;
        #(`CYCLE);
        WEN = 1; RW = 3'd0; busW = 8'd55;  // Write 55 to reg[0]
        #(`CYCLE);
        WEN = 0; RX = 3'd0; RY = 3'd1;  
        $display("Test r0 - busX: %d, busY: %d", busX, busY);
        if (busX === 0) $display("PASS, r0");
        else begin
            $display("FAIL, busX should be zero.");
            fail = 1'b1;
        end

        #(`CYCLE);
        WEN = 1; RW = 3'd1; RX = 3'd0; RY = 3'd1; busW = 8'd100; // r1 = 100
        #(`HCYCLE);
        $display("Test r1 - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd0) && (busY === 8'd100)) $display("PASS, r1");
        else begin
            $display("FAIL, busY should be 100.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 100, r2 = 50
        WEN = 1; RW = 3'd2; RX = 3'd1; RY = 3'd2; busW = 8'd50; 
        #(`HCYCLE);
        $display("Test translate - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd100) && (busY === 8'd50)) $display("PASS, translate display");
        else begin
            $display("FAIL, Answer should be X=100, Y=50.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 100, r2 = 50
        WEN = 0; RW = 3'd1; RX = 3'd0; RY = 3'd1; busW = 8'd30; 
        #(`HCYCLE);
        $display("Test WEN - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd0) && (busY === 8'd100)) $display("PASS, display");
        else begin
            $display("FAIL, Answer should be X=0, Y=100.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 100, r2 = 50, r7 = 32
        WEN = 1; RW = 3'd7; RX = 3'd7; RY = 3'd7; busW = 8'd32; 
        #(`HCYCLE);
        $display("Test translate - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd32) && (busY === 8'd32)) $display("PASS, Same reg display");
        else begin
            $display("FAIL, Answer should be X=32, Y=32.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 26, r2 = 50, r7 = 32
        WEN = 1; RW = 3'd1; RX = 3'd2; RY = 3'd1; busW = 8'd26; 
        #(`HCYCLE);
        $display("Test repeat - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd50) && (busY === 8'd26)) $display("PASS, Repeat display");
        else begin
            $display("FAIL, Answer should be X=50, Y=26.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 26, r2 = 50, r5 = 255, r7 = 32
        WEN = 1; RW = 3'd5; RX = 3'd5; RY = 3'd0; busW = 8'd255; 
        #(`HCYCLE);
        $display("Test Maximum - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd255) && (busY === 8'd0)) $display("PASS, Maximum display");
        else begin
            $display("FAIL, Answer should be X=255, Y=0.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 26, r2 = 50, r5 = 255, r7 = 32
        WEN = 0; RW = 3'd6; RX = 3'd1; RY = 3'd7; busW = 8'd105; 
        #(`HCYCLE);
        $display("Test WEN - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd26) && (busY === 8'd32)) $display("PASS, WEN=0 display");
        else begin
            $display("FAIL, Answer should be X=26, Y=32.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 26, r2 = 50, r4 = 207, r5 = 255, r7 = 32
        WEN = 1; RW = 3'd4; RX = 3'd0; RY = 3'd2; busW = 8'd207; 
        #(`HCYCLE);
        $display("Test  - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd0) && (busY === 8'd50)) $display("PASS, display");
        else begin
            $display("FAIL, Answer should be X=0, Y=50.");
            fail = 1'b1;
        end

        #(`HCYCLE); // r1 = 26, r2 = 50, r4 = 207, r5 = 255, r6 = 99, r7 = 32
        WEN = 1; RW = 3'd6; RX = 3'd4; RY = 3'd6; busW = 8'd99; 
        #(`HCYCLE);
        $display("Test prewritting - busX: %d, busY: %d", busX, busY);
        if ((busX === 8'd207) && (busY === 8'd99)) $display("PASS, Prewritting display");
        else begin
            $display("FAIL, Answer should be X=207, Y=99.");
            fail = 1'b1;
        end


        if (fail) $display("\n--------There is something wrong--------");
        else $display("\n--------All Correct--------");
        #(`CYCLE) $finish;
    end
    always #(`HCYCLE) Clk = ~Clk;
endmodule
