module shift_add_mul(
    clk,
    rst_n,
    start,
    in_A,
    in_B,
    out_data,
    ready
    );

    input clk;
    input rst_n;
    input start;
    input [31:0] in_A, in_B;
    output reg [63:0] out_data;
    output reg ready;

    reg [63:0] prod_rem;
    reg [31:0] A_temp;
    reg [5:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) count <= 5'd0;
        else if (start) count <= 5'd0;
        else if (count < 5'd31) count <= count + 5'd1;
        else if (count == 5'd31) count <= 5'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) prod_rem <= 64'd0;
        else if (start) prod_rem <= {32'd0, in_B};
        else if (count < 5'd31) begin
            if (prod_rem[0]) prod_rem <= ({{1'b0, prod_rem[63:32]} + {1'b0, A_temp}, prod_rem[31:0]} >> 1'b1);
            else prod_rem <= prod_rem >> 1;
        end
        else if (count == 5'd31) prod_rem <= 64'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) A_temp <= 32'd0;
        else if (start) A_temp <= in_A;
        else if (count == 5'd31) A_temp <= 32'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ready <= 1'b0;
        else if (start) ready <= 1'b0;
        else if (count == 5'd31) ready <= 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) out_data <= 64'd0;
        else if (start) out_data <= 64'd0;
        else if (count == 5'd31) out_data <= prod_rem;
    end
    
endmodule