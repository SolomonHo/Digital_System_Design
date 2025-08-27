`define CYCLE_TIME 20.0
`define OUT_DELAY_CYCLE 2
`define MAX_TIME 200000

module PATTERN(
    clk,
    rst_n,
    in_a,
    in_b,
    out
);

//=================================================
// input and output declaration
//=================================================
output reg  [6:0] in_a, in_b;
input  wire [7:0] out;
output reg        clk;
output reg        rst_n;

//=================================================
// parameter and integer
//=================================================
integer PATNUM = 10;
integer total_latency;
integer patcount;
integer file_in_a, file_in_b, file_out;
integer golden_out;
integer i;
integer c1, c2, c3;

//=================================================
// clock
//=================================================
initial clk = 0;
always #(`CYCLE_TIME/2.0) clk = ~clk;

//=================================================
// initial
//=================================================
initial begin
    // initial
    in_a = 'bx;
    in_b = 'bx;
    golden_out = 0;
    rst_n = 1;

    // open file
    file_in_a = $fopen("../00_TESTBED/input_a.txt", "r");
    file_in_b = $fopen("../00_TESTBED/input_b.txt", "r");
    file_out = $fopen("../00_TESTBED/output.txt", "r");

    // reset
    @(negedge clk);
    rst_n = 0;
    repeat(10) @(negedge clk);
    rst_n = 1;

    // drive and check
    @(negedge clk);
    for(patcount = 0; patcount < PATNUM + `OUT_DELAY_CYCLE; patcount = patcount + 1) begin
        if(patcount < PATNUM) begin
            gen_data;
        end
        if(patcount >= `OUT_DELAY_CYCLE) begin
            gen_golden;
            check_ans;
        end
        @(negedge clk);
    end

    // pass
    display_pass;
    repeat(3) @(negedge clk);
    $fclose(file_in_a);
    $fclose(file_in_b);
    $fclose(file_out);
    $finish();
end

//=================================================
// max time
//=================================================
initial begin
    #(`MAX_TIME);
    $display("------------------------------");
    $display("          out of time         ");
    $display("------------------------------");
    $finish();
end

//=================================================
// gen data and golden
//=================================================
task gen_data; begin
    c1 = $fscanf(file_in_a, "%d", in_a);
    c2 = $fscanf(file_in_b, "%d", in_b);
end endtask

task gen_golden; begin
    c3 = $fscanf(file_out, "%d", golden_out);
end endtask

//=================================================
// check ans
//=================================================
task check_ans; begin
    if(out !== golden_out) begin
        $display("------------------------------");
        $display(" pattern NO. %d               ", patcount - `OUT_DELAY_CYCLE);
        $display(" golden: %d                   ", golden_out);
        $display(" yours: %d                    ", out);
        $display("------------------------------");
        #(50);
        $finish();
    end else begin
        $display(" pass pattern NO. %d          ", patcount - `OUT_DELAY_CYCLE);
    end
end endtask

//=================================================
// display pass
//=================================================
task display_pass; begin
    $display("------------------------------");
    $display("             pass             ");
    $display("------------------------------");
end endtask

endmodule