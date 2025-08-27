module simple_calculator(
    Clk,
    WEN,
    RW,
    RX,
    RY,
    DataIn,
    Sel,
    Ctrl,
    busY,
    Carry
);

    input        Clk;
    input        WEN;
    input  [2:0] RW, RX, RY;
    input  [7:0] DataIn;
    input        Sel;
    input  [3:0] Ctrl;
    output [7:0] busY;
    output       Carry;

// declaration of wire/reg
    reg [7:0] x, y;
    wire [7:0] busW, busX;
// submodule instantiation
    alu_always alu(
        .ctrl(Ctrl),
        .x(x),
        .y(y),
        .carry(Carry),
        .out(busW)
    );

    register_file Regf(
        .Clk(Clk),
        .WEN(WEN),
        .RW(RW),
        .busW(busW),
        .RX(RX),
        .RY(RY),
        .busX(busX),
        .busY(busY)
    );

    always@(*) begin
        if (Sel) x = busX;
        else x = DataIn;
    end

    always@(busY) y = busY;

endmodule


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
module register_file(
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
output reg [7:0] busX, busY;
    
// write your design here, you can delcare your own wires and regs. 
// The code below is just an eaxmple template
reg [7:0] r0_w, r1_w, r2_w, r3_w, r4_w, r5_w, r6_w, r7_w;
reg [7:0] r0_r, r1_r, r2_r, r3_r, r4_r, r5_r, r6_r, r7_r;
    
always @(*) begin
    r0_r = r0_w;
    r1_r = r1_w;
    r2_r = r2_w;
    r3_r = r3_w;
    r4_r = r4_w;
    r5_r = r5_w;
    r6_r = r6_w;
    r7_r = r7_w;
end

always@(*) begin
    r0_w = 8'd0;
end
always@(*) begin
    case (RX) 
        //3'b000: busX = 8'd0;
        3'b001: busX = r1_r;
        3'b010: busX = r2_r;
        3'b011: busX = r3_r;
        3'b100: busX = r4_r;
        3'b101: busX = r5_r;
        3'b110: busX = r6_r;
        3'b111: busX = r7_r;
        default: busX = r0_r;
    endcase
end

always@(*) begin
    case (RY) 
        //3'b000: busY = 8'd0;
        3'b001: busY = r1_r;
        3'b010: busY = r2_r;
        3'b011: busY = r3_r;
        3'b100: busY = r4_r;
        3'b101: busY = r5_r;
        3'b110: busY = r6_r;
        3'b111: busY = r7_r;
        default: busY = r0_r;
    endcase
end

always@(posedge Clk) begin
    if (WEN) begin
        case (RW) 
            3'b001: r1_w <= busW;
            3'b010: r2_w <= busW;
            3'b011: r3_w <= busW;
            3'b100: r4_w <= busW;
            3'b101: r5_w <= busW;
            3'b110: r6_w <= busW;
            3'b111: r7_w <= busW;
            default: r0_w <= 8'd0;
        endcase 
    end 
    else begin
        case (RW) 
            3'b001: r1_w <= r1_r;
            3'b010: r2_w <= r2_r;
            3'b011: r3_w <= r3_r;
            3'b100: r4_w <= r4_r;
            3'b101: r5_w <= r5_r;
            3'b110: r6_w <= r6_r;
            3'b111: r7_w <= r7_r;
            default: r0_w <= 8'd0;
        endcase 
    end
end	

endmodule
