`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);
    input   clk ;
    input   reset ;
    input   in_en;
    output  out_valid;
    input   [15:0]  b_in;
    output  [31:0]  x_out;

    parameter INIT = 2'b00, ITERATE = 2'b01, OUTPUT = 2'b10, DONE = 2'b11;

    reg [1:0] state, next_state;
    reg signed [15:0] B [0:15];
    reg signed [31:0] x [0:15];
    reg [3:0] out_index, b_cnt, i;
    reg [6:0] iter_cnt;
    reg signed [31:0] scd, thrd, forth;
    reg signed [31:0] xi;
    reg signed [37:0] extend; //35
    
    reg signed[36:0] test1, test2;
    reg [2:0] run;

//============================================================//

//========================FSM====================================//
    always @(*) begin
        case (state)
            INIT: next_state = (b_cnt >= 4'd4) ? ITERATE : INIT; 
            ITERATE: next_state = (iter_cnt != 7'd85) ? ITERATE : OUTPUT;
            OUTPUT : next_state = (out_index != 4'd15) ? OUTPUT : DONE;
            default: next_state = INIT;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 2'b00;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge clk) begin
        if (in_en) begin
            B[b_cnt] <= b_in;
        end 
    end

    always@(posedge clk or posedge reset) begin
        if (reset) begin
            iter_cnt <= 7'd0;
        end
        else if (i == 4'd15 && run == 3'd7) begin
            iter_cnt <= iter_cnt + 7'd1;
        end
    end
//============================================================//

    assign out_valid = (state == OUTPUT) ? 1'b1 : 1'b0;
    assign x_out = (state == OUTPUT) ? x[out_index] : 32'd0; 
    // always @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         x_out <= 32'd0;
    //     end
    //     else if (state == OUTPUT) begin
    //         x_out <= x[out_index];
    //     end
    // end

    function signed [31:0] mult13;
        input signed [31:0] x;
        reg signed [35:0] temp;
        begin
            temp = (x <<< 3) + (x <<< 2) + x;
            mult13 = temp;
        end 
    endfunction
    function signed [31:0] mult6;
        input signed [31:0] x;
        reg signed [34:0] temp;
        begin
            temp = (x <<< 2) + (x <<< 1);
            mult6 = temp;
        end 
    endfunction

    always @(*) begin
        if (i == 0) begin
            scd = x[i+1];
        end
        else if (i == 15) begin
            scd = x[i-1];
        end 
        else begin
            scd = x[i+1] + x[i-1];
        end
    end

    always @(*) begin
        if (i < 2) begin
            thrd = x[i+2];
        end
        else if (i > 13) begin
            thrd = x[i-2];
        end  
        else begin
            thrd = x[i+2] + x[i-2];
        end
    end

    always @(*) begin
        if (i < 3) begin
            forth = x[i+3];
        end
        else if (i > 12) begin
            forth = x[i-3];
        end 
        else begin
            forth = x[i+3] + x[i-3];
        end
    end

    // assign test1 = $signed({B[i], 16'd0}) + scd * 13;//mult13(scd);
    // assign test2 = forth - thrd * 6;//mult6(thrd);
    // assign extend = test1 + test2;
    // assign xi = extend / 20;
    reg signed [39:0] z,s,c,r; // 37
    // >>>2  0.2 ===  m=3 n=4
    // assign z = $signed(extend >>> 4);
    // assign s = ($signed(z >>> 4) + $signed(z)) * 3;
    // assign c = $signed(s >>> 8) + $signed(s);
    // assign r = $signed(c >>> 16) + $signed(c);
    // assign p = $signed(r >>> 32) + $signed(r);
    // assign xi = p >>> 2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            test1 <= 37'd0;
            test2 <= 37'd0;
            extend <= 38'd0;
        end 
        else if (state == ITERATE) begin 
            test1 <= $signed({B[i], 16'd0}) + scd * 13;
            test2 <= forth - thrd * 6; // i = 1
            extend <= test1 + test2;// i = 2
            z <= $signed(extend >>> 4) * 3; // i=3
            s <= ($signed(z >>> 4) + $signed(z)); // i=4
            c <= $signed(s >>> 8) + $signed(s); // i=5
            r <= $signed(c >>> 16) + $signed(c); // i=6
            xi <= r >>> 2; // i=7 
        end
    end  

    integer j;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (j = 0; j < 16; j = j+1)
                x[j] <= 32'd0;
        end
        else begin
            if (in_en && state == INIT) begin
                x[b_cnt] <= {b_in, 16'd0};  // x[b_cnt] <= {{4{b_in[15]}}, b_in, 12'd0}; // b_in >> 4
            end
            else if (state == ITERATE && iter_cnt != 7'd85) begin
                x[i] <= xi; // x[i-2] <= xi;
            end
        end
    end

    always@(posedge clk or posedge reset) begin
        if (reset) begin
            b_cnt <= 4'd0;
        end
        // else if(b_cnt == 15) begin
        //     b_cnt <= 4'd0;
        // end
        else if (in_en) begin
            b_cnt <= b_cnt + 1;
        end
    end

    always@(posedge clk or posedge reset) begin
        if (reset) begin
            i <= 4'd0;
        end
        else if (b_cnt == 4'd4 && in_en) begin
            i <= 4'd0;
        end
        else if (run == 3'd7) begin
            i <= i + 4'd1;
        end
    end

    always@(posedge clk or posedge reset) begin
        if (reset) begin
            run <= 3'd0;
        end
        else if (b_cnt == 4'd4 && in_en) begin
            run <= 3'd0;
        end
        else begin
            run <= run + 3'd1;
        end
    end


    // always@(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         x_out <= 32'd0;
    //     end
    //     else if (state == OUTPUT) begin
    //         x_out <= x[out_index];
    //     end
    // end

    always@(posedge clk or posedge reset) begin
        if (reset) begin
            out_index <= 4'd0;
        end
        else if (state == OUTPUT) begin
            out_index <= out_index + 4'd1;
        end
    end

    // always@(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         out_valid <= 1'd0;
    //     end
    //     else if (state == OUTPUT) begin
    //         out_valid <= 1'b1;
    //     end
    // end

endmodule



