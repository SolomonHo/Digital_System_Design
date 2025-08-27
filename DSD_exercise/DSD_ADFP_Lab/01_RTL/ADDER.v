module ADDER(
    clk,
    rst_n,
    in_a,
    in_b,
    out
);

input       [6:0] in_a, in_b;
output reg  [7:0] out;
input             clk, rst_n;

reg [6:0] in_a_buffer, in_b_buffer;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_a_buffer <= 0;
        in_b_buffer <= 0;
        out <= 0;
    end else begin
        in_a_buffer <= in_a;
        in_b_buffer <= in_b;
        out <= in_a_buffer + in_b_buffer;
    end
end

endmodule