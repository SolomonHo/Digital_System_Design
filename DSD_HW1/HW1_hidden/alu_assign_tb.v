//continuous assignment tb
`timescale 1ns/10ps
`define CYCLE   10
`define HCYCLE  5

module alu_assign_tb;
    reg  [3:0] ctrl;
    reg signed  [7:0] x;
    reg signed [7:0] y;
    wire       carry;
    wire signed [7:0] out;
    reg signed [8:0] out_gold;

    wire signed [8:0] carry_out;

    assign carry_out = {carry, out[7:0]};
    
    alu_assign alu_assign(
        ctrl     ,
        x        ,
        y        ,
        carry    ,
        out  
    );

//    initial begin
//        $fsdbDumpfile("alu_assign.fsdb");
//        $fsdbDumpvars;
//    end

   integer error_count;

    initial begin
        error_count = 0;
        ctrl = 4'b0000;
        x    = -8'd100;
        y = 8'd105;
        out_gold = 9'd5;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b0000;
        x    = 8'd100;
        y = -8'd105;
        out_gold = -9'd5;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b0000;
        x    = 8'd125;
        y = 8'd125;
        out_gold = 9'd250;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b0001;
        x    = -8'd125;
        y    = 8'd125;
        out_gold = -9'd250;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b, x = %d, y = %d, out = %d, out_gold = %d", ctrl, x, y, carry_out, out_gold);
        end

        #(`HCYCLE);
        ctrl = 4'b0001;
        x    = 8'd125;
        y    = -8'd125;
        out_gold = 9'd250;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b, x = %d, y = %d, out = %d, out_gold = %d", ctrl, x, y, carry_out, out_gold);
        end

        #(`HCYCLE);
        ctrl = 4'b0010;
        x    = 8'd125;
        y    = 8'd80;
        out_gold = x&y;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== 0))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end


        #(`HCYCLE);
        ctrl = 4'b0011;
        x    = 8'd125;
        y    = 8'd80;
        out_gold = x|y;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== 0))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end
        

        #(`HCYCLE);
        ctrl = 4'b0100;
        x    = 8'd135;
        out_gold = ~x;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== 0))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b0101;
        x    = 8'd135;
        y = 8'd100;
        out_gold = x^y;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== 0))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b0110;
        x    = 8'd135;
        y = 8'd100;
        out_gold = ~(x|y);
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== 0))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b0111;
        x    = 8'b1111_1010;
        y = 8'b1000_0101;
        out_gold = 9'b000010100;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1000;
        x    = 8'b1111_1010;
        y = 8'b1000_0101;
        out_gold = 9'b000100001;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1001;
        x = 8'b1111_1010;
        out_gold = 9'b011111_101;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1010;
        x = 8'b1111_1010;
        out_gold = 9'b111_10101;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1011;
        x = 8'b1111_1010;
        out_gold = 9'b001111_101;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1100;
        x    = 8'd9;
        y    = 8'd9;
        out_gold = 9'd1;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1100;
        x    = 8'd9;
        y    = 8'd10;
        out_gold = 9'd0;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1101;
        out_gold = 9'd0;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1110;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        #(`HCYCLE);
        ctrl = 4'b1111;
        #(`HCYCLE);
        if ((out !== out_gold[7:0])||(carry !== out_gold[8]))begin
            error_count = error_count + 1;
            $display("Error at ctrl = : %b", ctrl);
        end

        if( error_count==0 ) begin
            $display("****************************        /|__/|");
            $display("**                        **      / O,O  |");
            $display("**   Congratulations !!   **    /_____   |");
            $display("** All Patterns Passed!!  **   /^ ^ ^ \\  |");
            $display("**                        **  |^ ^ ^ ^ |w|");
            $display("****************************   \\m___m__|_|");
        end
        else begin
            $display("**************************** ");
            $display("           Failed ...        ");
            $display("     Total %2d Errors ...     ", error_count );
            $display("**************************** ");
        end






        // ctrl = 4'b1101;
        // x    = 8'd0;
        // y    = 8'd0;
        
        // #(`CYCLE);
        // // 0100 boolean not
        // ctrl = 4'b0100;
        
        // #(`HCYCLE);
        // if( out == 8'b1111_1111 ) $display( "PASS --- 0100 boolean not" );
        // else $display( "FAIL --- 0100 boolean not" );
        
        // finish tb
        #(`CYCLE) $finish;
    end

endmodule
