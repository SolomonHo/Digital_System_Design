//RT �Vlevel (event-driven) 
module alu_always(
    ctrl,
    x,
    y,
    carry,
    out 
);
    
    input  [3:0] ctrl;
    input  [7:0] x;
    input  [7:0] y;
    output  reg   carry;
    output reg [7:0] out;
    
    reg signed [8:0] sum, sub;
    reg  [7:0] forw, back;


    always @(*) begin
        // sum & sub
        sum = {x[7], x} + {y[7], y};
        sub = {x[7], x} - {y[7], y};
    end

    always @(*) begin
        // carry
        case (ctrl)
            4'b0000: carry = sum[8];
            4'b0001: carry = sub[8];
            default: carry = 1'b0;
        endcase
    end

    always @(*) begin
        // forward logic
        case (ctrl[2:0])
            3'b000: forw = sum[7:0];
            3'b001: forw = sub[7:0];
            3'b010: forw = x & y;
            3'b011: forw = x | y;
            3'b100: forw = ~x;
            3'b101: forw = x ^ y;
            3'b110: forw = ~(x | y);
            3'b111: forw = y << x[2:0];
            default: forw = 8'd0;
        endcase

        // backward logic
        case (ctrl[2:0])
            3'b000: back = y >> x[2:0];
            3'b001: back = {x[7], x[7:1]};     
            3'b010: back = {x[6:0], x[7]};     
            3'b011: back = {x[0], x[7:1]};     
            3'b100: back = (x == y) ? 8'd1 : 8'd0; 
            default: back = 8'd0;
        endcase

        // result
        if (ctrl[3])
            out = back;
        else
            out = forw;
    end

endmodule
