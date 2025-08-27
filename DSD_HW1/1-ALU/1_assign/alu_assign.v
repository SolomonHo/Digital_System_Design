//RTL (use continuous assignment)
module alu_assign(
    ctrl,
    x,
    y,
    carry,
    out  
);
    
    input  [3:0] ctrl;
    input  [7:0] x;
    input  [7:0] y;
    output       carry;
    output [7:0] out;

    wire signed [8:0] sum, sub;
    wire  [7:0] forw, back;

    assign sum = {x[7], x} + {y[7], y};
    assign sub = {x[7], x} - {y[7], y};

// carry
    assign carry = (ctrl == 4'b0000) ? sum[8] :
                   (ctrl == 4'b0001) ? sub[8] : 1'b0;
// Control
    assign forw = (ctrl[2:0] == 3'b000) ? sum[7:0] :
                  (ctrl[2:0] == 3'b001) ? sub[7:0] : 
                  (ctrl[2:0] == 3'b010) ? x & y :
                  (ctrl[2:0] == 3'b011) ? x | y : 
                  (ctrl[2:0] == 3'b100) ? ~x :
                  (ctrl[2:0] == 3'b101) ? x ^ y :
                  (ctrl[2:0] == 3'b110) ? ~(x | y) :
                  y << x[2:0];

    assign back = (ctrl[2:0] == 3'b000) ? y >> x[2:0] :
                  (ctrl[2:0] == 3'b001) ? {x[7], x[7:1]} : 
                  (ctrl[2:0] == 3'b010) ? {x[6:0], x[7]} :
                  (ctrl[2:0] == 3'b011) ? {x[0], x[7:1]} : 
                  (ctrl[2:0] == 3'b100) ? (x == y) : 8'd0;

// result
    assign out = ctrl[3] ? back : forw;

endmodule
