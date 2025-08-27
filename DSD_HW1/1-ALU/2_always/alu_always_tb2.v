//always block tb
`timescale 1ns/10ps
`define CYCLE	10
`define HCYCLE	5

module alu_always_tb;
    reg  [3:0] ctrl;
    reg  [7:0] x;
    reg  [7:0] y;
    wire       carry;
    wire [7:0] out;
    reg fail;

    alu_always alu_always(
        ctrl     ,
        x        ,
        y        ,
        carry    ,
        out  
    );

   initial begin
       $fsdbDumpfile("alu_always.fsdb");
       $fsdbDumpvars;
   end

    initial begin
        ctrl = 4'b1101;
        x    = 8'd0;
        y    = 8'd0;
        
        #(`CYCLE);
        // 0100 boolean not
        ctrl = 4'b0100;
        #(`HCYCLE);
        if( out === 8'b1111_1111 ) $display( "PASS --- 0100 boolean not" );
        else begin
            $display( "FAIL --- 0100 boolean not" );
            fail = 1'b1;
        end

        #(`HCYCLE);
        x    = 8'd5;
        y    = 8'd3;    
        ctrl = 4'b0000;   
        #(`HCYCLE);
        if( out === 8'd8 && carry === 1'b0 ) $display("PASS --- 0000 Add ");
        else begin
            $display("FAIL --- 0000 Add");
            fail = 1'b1;
        end

        #(`HCYCLE);
        x    = 8'b11110110; //-10
        y    = 8'b11101100; //-20    
        ctrl = 4'b0000;   
        #(`HCYCLE);
        if( out === 8'b1110_0010 && carry === 1'b1 ) $display("PASS --- 0000 Add ");
        else begin
            $display("FAIL --- 0000 Add");
            // $display("out = %b carry = %b", out, carry);
            fail = 1'b1;
        end

        #(`HCYCLE); //add
        x    = 8'd255;
        y    = 8'd1; 
        ctrl = 4'b0000;   
        #(`HCYCLE);
        if( out === 8'd0 && carry === 1'b0 ) $display("PASS --- 0000 Add (signed)");
        else begin
            $display("FAIL --- 0000 Add (signed)");
            fail = 1'b1;
        end

        #(`HCYCLE); //add
        x    = 8'd255;
        y    = 8'd255; 
        ctrl = 4'b0000;   
        #(`HCYCLE);
        if( out === 8'b11111110 && carry === 1'b1 ) $display("PASS --- 0000 Add (overflow)");
        else begin
            $display("FAIL --- 0000 Add (overflow)");
            fail = 1'b1;
        end

        #(`HCYCLE); //add
        x    = 8'd255;
        y    = 8'd1; 
        ctrl = 4'b0000;   
        #(`HCYCLE);
        if( out === 8'd0 && carry === 1'b0 ) $display("PASS --- 0000 Add (overflow)");
        else begin
            $display("FAIL --- 0000 Add (overflow)");
            fail = 1'b1;
        end

        #(`HCYCLE); //sub
        x    = 8'd0;
        y    = 8'd1; 
        ctrl = 4'b0001;   
        #(`HCYCLE);
        if( out === 8'd255 && carry === 1'b1 ) $display("PASS --- 0000 Sub (signed)");
        else begin
            $display("FAIL --- 0000 Sub (signed)");
            fail = 1'b1;
        end

        #(`HCYCLE); //sub
        x    = 8'd1;
        y    = 8'd255; 
        ctrl = 4'b0001;   
        #(`HCYCLE);
        if( out === 8'd2 && carry === 1'b0 ) $display("PASS --- 0000 Sub (signed)");
        else begin
            $display("FAIL --- 0000 Sub (signed)");
            fail = 1'b1;
        end

        #(`HCYCLE); //sub
        x    = 8'd0;
        y    = 8'd0; 
        ctrl = 4'b0001;   
        #(`HCYCLE);
        if( out === 8'd0 && carry === 1'b0 ) $display("PASS --- 0000 Sub (signed)");
        else begin
            $display("FAIL --- 0000 Sub (signed)");
            fail = 1'b1;
        end

        #(`HCYCLE); //and
        x = 8'b10101010;
        y = 8'b11001100;
        ctrl = 4'b0010;   
        #(`HCYCLE);
        if( out === 8'b10001000 && carry === 1'b0 ) $display("PASS --- 0000 And");
        else begin
            $display("FAIL --- 0000 And");
            fail = 1'b1;
        end

        #(`HCYCLE); //and
        x = 8'b11111111;
        y = 8'b11111111;
        ctrl = 4'b0010;   
        #(`HCYCLE);
        if( out === 8'b1111_1111 && carry === 1'b0 ) $display("PASS --- 0000 And");
        else begin
            $display("FAIL --- 0000 And");
            fail = 1'b1;
        end

        #(`HCYCLE); //and
        x = 8'd0;
        y = 8'd0;
        ctrl = 4'b0010;   
        #(`HCYCLE);
        if( out === 8'd0 && carry === 1'b0 ) $display("PASS --- 0000 And");
        else begin
            $display("FAIL --- 0000 And");
            fail = 1'b1;
        end

        #(`HCYCLE); //and
        x = 8'b10101010;
        y = 8'b01010101;
        ctrl = 4'b0010;   
        #(`HCYCLE);
        if( out === 8'd0 && carry === 1'b0 ) $display("PASS --- 0000 And");
        else begin
            $display("FAIL --- 0000 And");
            fail = 1'b1;
        end

        #(`HCYCLE); //or
        x = 8'b10101010;
        y = 8'b11001100;
        ctrl = 4'b0011;   
        #(`HCYCLE);
        if( out === 8'b11101110 && carry === 1'b0 ) $display("PASS --- 0000 Or");
        else begin
            $display("FAIL --- 0000 Or");
            fail = 1'b1;
        end

        #(`HCYCLE); //or
        x = 8'b1100101;
        y = 8'b0010100;
        ctrl = 4'b0011;   
        #(`HCYCLE);
        if( out === 8'b1110101 && carry === 1'b0 ) $display("PASS --- 0000 Or");
        else begin
            $display("FAIL --- 0000 Or");
            fail = 1'b1;
        end

        #(`HCYCLE); //Not
        x = 8'b10101010;
        ctrl = 4'b0100;   
        #(`HCYCLE);
        if( out === 8'b01010101 && carry === 1'b0 ) $display("PASS --- 0000 Not");
        else begin
            $display("FAIL --- 0000 Not");
            fail = 1'b1;
        end

        #(`HCYCLE); //Not
        x = 8'd0;
        ctrl = 4'b0100;   
        #(`HCYCLE);
        if( out === 8'b1111_1111 && carry === 1'b0 ) $display("PASS --- 0000 Not");
        else begin
            $display("FAIL --- 0000 Not");
            fail = 1'b1;
        end

        #(`HCYCLE); //Xor
        x = 8'b10101010;
        y = 8'b11001100;
        ctrl = 4'b0101;   
        #(`HCYCLE);
        if( out === 8'b01100110 && carry === 1'b0 ) $display("PASS --- 0000 Xor");
        else begin
            $display("FAIL --- 0000 Xor");
            fail = 1'b1;
        end

        #(`HCYCLE); //Xor
        x = 8'd1;
        y = 8'd255;
        ctrl = 4'b0101;   
        #(`HCYCLE);
        if( out === 8'b1111_1110 && carry === 1'b0 ) $display("PASS --- 0000 Xor");
        else begin
            $display("FAIL --- 0000 Xor");
            fail = 1'b1;
        end

        #(`HCYCLE); //Xor
        x = 8'd168;
        y = 8'd168;
        ctrl = 4'b0101;   
        #(`HCYCLE);
        if( out === 8'd0 && carry === 1'b0 ) $display("PASS --- 0000 Xor");
        else begin
            $display("FAIL --- 0000 Xor");
            fail = 1'b1;
        end

        #(`HCYCLE); //Xor
        x = 8'd0;
        y = 8'd168;
        ctrl = 4'b0101;   
        #(`HCYCLE);
        if( out === 8'd168 && carry === 1'b0 ) $display("PASS --- 0000 Self-Xor");
        else begin
            $display("FAIL --- 0000 Self-Xor");
            fail = 1'b1;
        end

        #(`HCYCLE); //Nor
        x = 8'b10101010;
        y = 8'b11001100;
        ctrl = 4'b0110;   
        #(`HCYCLE);
        if( out === 8'b00010001 && carry === 1'b0 ) $display("PASS --- 0000 Nor");
        else begin
            $display("FAIL --- 0000 Nor");
            fail = 1'b1;
        end

        #(`HCYCLE); //Nor
        x = 8'b1111_0000;
        y = 8'b0000_1111;
        ctrl = 4'b0110;   
        #(`HCYCLE);
        if( out === 8'd0 && carry === 1'b0 ) $display("PASS --- 0000 Nor");
        else begin
            $display("FAIL --- 0000 Nor");
            fail = 1'b1;
        end

        #(`HCYCLE); //shift left
        x = 8'd2;
        y = 8'd1;
        ctrl = 4'b0111;   
        #(`HCYCLE);
        if( out === 8'b00000100 && carry === 1'b0 ) $display("PASS --- 0000 Shift left");
        else begin
            $display("FAIL --- 0000 Shift left");
            fail = 1'b1;
        end

        #(`HCYCLE); //shift left
        x = 8'b11001011;
        y = 8'd5;
        ctrl = 4'b0111;   
        #(`HCYCLE);
        if( out === 8'b00101000 && carry === 1'b0 ) $display("PASS --- 0000 Shift left");
        else begin
            $display("FAIL --- 0000 Shift left");
            fail = 1'b1;
        end

        #(`HCYCLE); //shift left
        x = 8'b01100111;
        y = 8'd10011101;
        ctrl = 4'b0111;   
        #(`HCYCLE);
        if( out === 8'b10000000 && carry === 1'b0 ) $display("PASS --- 0000 Shift left");
        else begin
            $display("FAIL --- 0000 Shift left");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1000;
        x = 8'd2;
        y = 8'b00000100;
        #(`HCYCLE);
        if (out === 8'b00000001 && carry === 0) $display("PASS --- 1000 Shift right logical ");
        else begin
            $display("FAIL --- 1000 Shift right logical");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1000;
        x = 8'd7;
        y = 8'b00100100;
        #(`HCYCLE);
        if (out === 8'b00000000 && carry === 0) $display("PASS --- 1000 Shift right logical ");
        else begin
            $display("FAIL --- 1000 Shift right logical");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1000;
        x = 8'd7;
        y = 8'b10100100;
        #(`HCYCLE);
        if (out === 8'b00000001 && carry === 0) $display("PASS --- 1000 Shift right logical ");
        else begin
            $display("FAIL --- 1000 Shift right logical");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1001;
        x = 8'd2;
        y = 8'b10000100;
        #(`HCYCLE);
        if (out === 8'b00000001 && carry === 0) $display("PASS --- 1001 Shift right arithmetic");
        else begin
            $display("FAIL --- 1001 Shift right arithmetic");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1001;
        x = 8'b10011001;
        y = 8'b10000100;
        #(`HCYCLE);
        if (out === 8'b11001100 && carry === 0) $display("PASS --- 1001 Shift right arithmetic");
        else begin
            $display("FAIL --- 1001 Shift right arithmetic");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1010;
        x = 8'b10101010;
        #(`HCYCLE);
        if (out === 8'b01010101 && carry === 0) $display("PASS --- 1010 Rotate left");
        else begin
            $display("FAIL --- 1010 Rotate left");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1011;
        x = 8'b10101010;
        #(`HCYCLE);
        if (out === 8'b01010101 && carry === 0) $display("PASS --- 1011 Rotate right");
        else begin
            $display("FAIL --- 1011 Rotate right");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1011;
        x = 8'b00111001;
        #(`HCYCLE);
        if (out === 8'b10011100 && carry === 0) $display("PASS --- 1011 Rotate right");
        else begin
            $display("FAIL --- 1011 Rotate right");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1100;
        x = 8'd5;
        y = 8'd5;
        #(`HCYCLE);
        if (out === 8'd1 && carry === 0) $display("PASS --- 1100 Equal");
        else begin
            $display("FAIL --- 1100 Equal");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1100;
        x = 8'd5;
        y = 8'd3;
        #(`HCYCLE);
        if (out === 8'd0 && carry === 0) $display("PASS --- 1100 Equal");
        else begin
            $display("FAIL --- 1100 Equal");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1101;
        x = 8'd12;
        y = 8'd3;
        #(`HCYCLE);
        if (out === 8'd0 && carry === 0) $display("PASS --- 1100 Nop");
        else begin
            $display("FAIL --- 1100 Nop");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1110;
        x = 8'd12;
        y = 8'd3;
        #(`HCYCLE);
        if (out === 8'd0 && carry === 0) $display("PASS --- 1100 Nop");
        else begin
            $display("FAIL --- 1100 Nop");
            fail = 1'b1;
        end

        #(`HCYCLE);
        ctrl = 4'b1111;
        x = 8'd12;
        y = 8'd3;
        #(`HCYCLE);
        if (out === 8'd0 && carry === 0) $display("PASS --- 1100 Nop");
        else begin
            $display("FAIL --- 1100 Nop");
            fail = 1'b1;
        end

        if (fail) $display("\n---------There is somthing wring--------\n");
        else $display("\n---------Correct--------\n");
        // finish tb
        #(`CYCLE) $finish;
    end
endmodule
