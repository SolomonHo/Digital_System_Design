`timescale 1ns/1ps
`define SYN_SDF_FILE "../02_SYN/Netlist/ADDER_syn.sdf"

module TESTBED ;

// connection wires
wire [6:0] in_a, in_b;
wire [7:0] out;
wire clk, rst_n;

// device under test
ADDER u_adder(
    .clk(clk),
    .rst_n(~rst_n),
    .in_a(in_a),
    .in_b(in_b),
    .enable(1'b1),
    .out(out)
);

// pattern generator
PATTERN u_pattern(
    .clk(clk),
    .rst_n(rst_n),
    .in_a(in_a),
    .in_b(in_b),
    .out(out)
);
    
// annotate and dump fsdb
initial begin
    `ifdef RTL
        $fsdbDumpfile("ADDER.fsdb");
        $fsdbDumpvars(0, "+mda");
        $fsdbDumpvars();
    `endif
    `ifdef GATE
        $sdf_annotate(`SYN_SDF_FILE, u_adder);
        $fsdbDumpfile("ADDER.fsdb");
        $fsdbDumpvars(0, "+mda");
    `endif
end

endmodule