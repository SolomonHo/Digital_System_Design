module core(clk,
            rst_n,
            // for mem_D
            mem_wen_D,
            mem_addr_D,
            mem_wdata_D,
            mem_rdata_D,
            // for mem_I
            mem_addr_I,
            mem_rdata_I
    );

    input         clk, rst_n ;
    // for mem_D
    output        mem_wen_D  ;  // mem_wen_D is high, core writes data to D-mem; else, core reads data from D-mem
    output [31:0] mem_addr_D ;  // the specific address to fetch/store data 
    output [31:0] mem_wdata_D;  // data writing to D-mem 
    input  [31:0] mem_rdata_D;  // data reading from D-mem
    // for mem_I
    output reg [31:0] mem_addr_I ;  // the fetching address of next instruction
    input  [31:0] mem_rdata_I;  // instruction reading from I-mem

//---------------------------------------//
    wire [31:0] instruction;
    wire Jalr, Jal, Branch, MemtoReg;
    wire [1:0] ALUOp;
    wire MemWrite, ALUSrc, RegWrite;
    wire [4:0] opcode;

    reg [4:0] rd, rs1, rs2;
    wire [31:0] rs1_data, rs2_data, rd_data;

    reg [31:0] imm, b;
    wire Zero;
    // wire funct7;
    wire [31:0] ALU_result, Sum;
    wire [2:0] funct3;
    reg [3:0] ALU_control;
    wire [31:0] PC_nxt;
    // reg [31:0] mux1;
//---------------------------------------//

//---------------------------------------//
    Control control(
            .opcode(opcode),
            // .Branch(Branch),
            .MemtoReg(MemtoReg), // equal to MemRead
            .ALUOp(ALUOp),
            .MemWrite(MemWrite),
            .ALUSrc(ALUSrc),
            .RegWrite(RegWrite)
            );

    Register register(
            .clk(clk),
            .rst_n(rst_n),
            .wen(RegWrite),
            .rs1(rs1),
            .rs2(rs2),
            .rd(rd),
            .rs1_data(rs1_data),
            .rs2_data(rs2_data),
            .rd_data(rd_data) // input
            );

    ALU alu(
            .a(rs1_data),
            .b(b),
            .ALU_control(ALU_control),
            .Zero(Zero),
            .ALU_result(ALU_result)
            );

//---------------------------------------//
    // function [31:0] little2big;
    //     input [31:0] data;
    //     begin
    //         little2big={data[7:0], data[15:8], data[23:16], data[31:24]};
    //     end
    // endfunction

    assign instruction = {mem_rdata_I[7:0], mem_rdata_I[15:8], mem_rdata_I[23:16], mem_rdata_I[31:24]};
    assign opcode = instruction[6:2];

    always @(*) begin
        rd = instruction[11:7];
        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
    end
    // assign funct7 = instruction[30];
    assign funct3 = instruction[14:12];

    
    // assign rd_data = (MemtoReg) ? {mem_rdata_D[7:0], mem_rdata_D[15:8], mem_rdata_D[23:16], mem_rdata_D[31:24]} : 
    //                               ALU_result;
    assign rd_data = (MemtoReg) ? {mem_rdata_D[7:0], mem_rdata_D[15:8], mem_rdata_D[23:16], mem_rdata_D[31:24]} : 
                     (Jal || Jalr) ? mem_addr_I + 32'd4 :
                      ALU_result;

    // ImmGen
    always @(*) begin
        case(opcode)
            5'b00000: imm = {{20{instruction[31]}}, instruction[31:20]}; // lw
            5'b11001: imm = {{20{instruction[31]}}, instruction[31:20]}; // jalr
            5'b01000: imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // sw
            5'b11000: imm = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // beq
            5'b11011: imm = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // jal
            5'b00100: imm = {{20{instruction[31]}}, instruction[31:20]}; // I-type
            default: imm = 32'd0; // R-type
        endcase
    end

    always @(*) begin
        b = (ALUSrc) ? imm : rs2_data;
    end

    // ALU control
    always @(*) begin
        case(ALUOp)
            2'b00: ALU_control = 4'b0000; // add (lw, sw, jal, jalr)
            2'b01: ALU_control = 4'b0001; // sub (beq, bne)
            2'b10: begin // R-type or I-type
                case(funct3)
                    3'b000: ALU_control = (opcode == 5'b01100 && instruction[30]) ? 4'b0001 : 4'b0000; // sub (R-type), add/addi
                    3'b001: ALU_control = 4'b0100; // sll/slli
                    3'b010: ALU_control = 4'b1000; // slt/slti
                    3'b100: ALU_control = 4'b0110; // xor/xori
                    3'b110: ALU_control = 4'b0011; // or/ori
                    3'b111: ALU_control = 4'b0010; // and/andi
                    3'b101: ALU_control = instruction[30] ? 4'b0101 : 4'b0111; // sra/srai, srl/srli
                    default: ALU_control = 4'b1111; // nop
                endcase
            end
            default: ALU_control = 4'b1111; // nop
        endcase
    end

    assign mem_wen_D = MemWrite;
    assign mem_addr_D = ALU_result;
    assign mem_wdata_D = {rs2_data[7:0], rs2_data[15:8], rs2_data[23:16], rs2_data[31:24]};

    // PC
    assign Sum = mem_addr_I + imm;
    assign Branch = (opcode == 5'b11000) && ((!funct3 && Zero) || (funct3[0] && !Zero)); 
    assign Jal = (opcode[4:1] == 4'b1101) ? 1'b1 : 1'b0;
    assign Jalr = (opcode == 5'b11001) ? 1'b1 : 1'b0;

    assign PC_nxt = (Branch || Jal) ?  Sum :
                    Jalr ?  (rs1_data + imm) & ~32'd1:
                    mem_addr_I + 32'd4;

    always @(posedge clk ) begin
        if (!rst_n) begin
            mem_addr_I <= 32'd0;
        end
        else begin
            mem_addr_I <= PC_nxt;
        end
    end

endmodule


module Control (
        opcode,
        // Branch,
        MemtoReg, // equal to MemRead
        ALUOp,
        MemWrite,
        ALUSrc,
        RegWrite
    );

    input [4:0] opcode;
    // output reg Branch;
    // output reg MemRead;
    output reg MemtoReg;
    output reg [1:0] ALUOp;
    output reg MemWrite;
    output reg ALUSrc;
    output RegWrite;

    always @(*) begin // lw 0000011
        MemtoReg = (opcode[3] == 1'b0) ? 1'b1 : 1'b0;
        // MemtoReg = (!opcode) ? 1'b0 : 1'b1;
    end
 
    // always @(*) begin
    //     case (opcode)
    //         5'b01100: ALUOp = 2'b10; // R-type
    //         5'b00100: begin
    //             case (funct3)
    //                 3'b001, 3'b101: ALUOp = 2'b10; // slli, srli, srai
    //                 default: ALUOp = 3'b011; // addi, andi, ori, xori, slti
    //             endcase
    //         end
    //         5'b00000: ALUOp = 3'b000; // lw
    //         5'b01000: ALUOp = 3'b000; // sw
    //         5'b11011: ALUOp = 3'b000; // jal
    //         5'b11001: ALUOp = 3'b000; // jalr
    //         5'b11000: ALUOp = 3'b001; // beq, bne
    //         default:    ALUOp = 3'b000; // default to add
    //     endcase
    // end
    always @(*) begin 
        case({opcode[4], opcode[2], opcode[0]}) // synopsys parallel_case
            3'b000, 3'b101: ALUOp = 2'b00; // lw, sw, jalr, (jal)
            3'b100: ALUOp = 2'b01; // beq
            3'b010: ALUOp = 2'b10; // R-type, I-type
            default: ALUOp = 2'b00;
        endcase
    end 

    always @(*) begin //opcode = 0100011
        MemWrite = (opcode[4:2] != 3'b010) ? 1'b0 : 1'b1;
    end 

    always @(*) begin 
        case({opcode[4:2], opcode[0]}) // synopsys parallel_case
            4'b0110, 4'b1100: ALUSrc = 1'b0; // R-type, beq
            4'b0010, 4'b0000, 4'b0100, 4'b1101: ALUSrc = 1'b1; // lw, sw, jal, jalr, I-type
            default: ALUSrc = 1'b0;
        endcase
    end

    // always @(*) begin 
    //     case({opcode[3:2], opcode[0]}) // synopsys parallel_case
    //         3'b100: RegWrite = 1'b0; // sw, beq
    //         3'b110, 3'b010, 3'b000, 3'b101: RegWrite = 1'b1; // R-type, lw, jal, jalr, I-type
    //         default: RegWrite = 1'b0;
    //     endcase
    // end
    assign RegWrite = ({opcode[3:2], opcode[0]} != 3'b100) ? 1'b1 : 1'b0;

endmodule

module Register(
        clk,
        rst_n,
        wen,
        rd_data,
        rs1,
        rs2,
        rd,
        rs1_data,
        rs2_data
    );

    input clk, rst_n, wen;
    input [31:0] rd_data;
    input [4:0] rs1, rs2, rd;
    output [31:0] rs1_data, rs2_data;

    reg [31:0] registers [0:31];
    // reg [31:0] registers_r [0:31];

    assign rs1_data = (rs1 != 0) ? registers[rs1] : 32'd0;
    assign rs2_data = (rs2 != 0) ? registers[rs2] : 32'd0;

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i <32; i = i+1 ) begin
                registers[i] <= 32'd0;
            end
        end
        else if (wen && (rd != 0)) begin
            registers[rd] <= rd_data;
        end 
        // else begin 
        //     registers[rd] <= registers_r[rd];
        // end
    end

endmodule

module ALU(
        a,
        b,
        ALU_control,
        Zero,
        ALU_result
        );

    input [31:0] a,b;
    input [3:0] ALU_control;
    output Zero;
    output reg [31:0] ALU_result;

    always @(*) begin
        case(ALU_control)
            4'b0000: ALU_result = a + b; // add, addi, lw, sw, jal, jalr
            4'b0001: ALU_result = a - b; // sub, beq, bne
            4'b0010: ALU_result = a & b; // and, andi
            4'b0011: ALU_result = a | b; // or, ori
            4'b0100: ALU_result = a << b[4:0]; // sll, slli
            4'b0101: ALU_result = $signed(a) >>> b[4:0]; // sra, srai
            4'b0110: ALU_result = a ^ b; // xor, xori
            4'b0111: ALU_result = a >> b[4:0]; // srl, srli
            4'b1000: ALU_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // slt, slti
            default: ALU_result = 32'd0; // nop
        endcase
    end

    // assign Zero = (ALU_result == 32'd0) ? 1'b1 : 1'b0;
    assign Zero = (a == b);

endmodule


    