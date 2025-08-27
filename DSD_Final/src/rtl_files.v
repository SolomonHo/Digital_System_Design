`include "CHIP.v"
// `include "D_cache.v"
// `include "I_cache.v"
// `include "cache_2way.v"
`include "cache_dm.v"
`include "ALU.v"
/// Add other verilog files here for example: `include "cache.v"
// Your SingleCycle RISC-V code

module  RISCV_Pipeline(clk,
                       rst_n,
                       // for mem_D
                       DCACHE_ren,
                       DCACHE_wen,
                       DCACHE_addr,
                       DCACHE_wdata,
                       DCACHE_stall,
                       DCACHE_rdata,
                       // for mem_I
                       ICACHE_ren,
                       ICACHE_wen,  
                       ICACHE_addr,
                       ICACHE_wdata, 
                       ICACHE_stall, 
                       ICACHE_rdata,
                       PC
    );

    input         clk, rst_n ;
    // for mem_D
    output        DCACHE_ren;
    output        DCACHE_wen;  // mem_wen_D is high, core writes data to D-mem; else, core reads data from D-mem
    output [29:0] DCACHE_addr;  // the specific address to fetch/store data 
    output [31:0] DCACHE_wdata;  // data writing to D-mem 
    input  [31:0] DCACHE_rdata;  // data reading from D-mem
    input         DCACHE_stall;
    // for mem_I
    output             ICACHE_ren;
    output             ICACHE_wen;
    output [29:0] ICACHE_addr;  // the fetching address of next instruction
    output [31:0] ICACHE_wdata;
    input           ICACHE_stall;
    input  [31:0] ICACHE_rdata;  // instruction reading from I-mem

    output reg [31:0] PC;

//------------Pipeline reg---------------------------//
    reg [31:0] IF_ID_PC, IF_ID_Inst;
    // ID/EX
    reg [31:0] ID_EX_PC, ID_EX_Inst, ID_EX_rs1_data, ID_EX_rs2_data, ID_EX_Imm;
    reg [4:0] ID_EX_rd, ID_EX_rs1, ID_EX_rs2;
    reg [1:0] ID_EX_ALUOp;
    reg ID_EX_MemtoReg, ID_EX_MemWrite, ID_EX_ALUSrc, ID_EX_RegWrite;
    wire ID_EX_MemWrite_stall, ID_EX_RegWrite_stall;
    // EX/MEM
    reg [31:0] EX_MEM_ALU_result, EX_MEM_rs2_data, EX_MEM_PC_branch;
    reg [4:0] EX_MEM_rd;
    reg EX_MEM_MemtoReg, EX_MEM_MemWrite, EX_MEM_RegWrite, EX_MEM_Zero, EX_MEM_Branch, EX_MEM_Jal, EX_MEM_Jalr;
    reg [31:0] EX_MEM_PC_plus4;   // ******************* modified
    // MEM/WB
    reg [31:0] MEM_WB_ALU_result, MEM_WB_mem_rdata, MEM_WB_PC_return;
    reg [4:0] MEM_WB_rd;
    reg MEM_WB_MemtoReg, MEM_WB_RegWrite;
    reg MEM_WB_Jal, MEM_WB_Jalr;
//---------------------------------------//
    wire [31:0] instruction;
    wire [31:0] PC_nxt, PC_branch;
    // reg [31:0] PC;
    wire Jalr, Jal, Branch, MemtoReg;
    wire MemWrite, ALUSrc, RegWrite, Zero;
    wire Flush, stall, lw_hazard;
    wire [1:0] ALUOp;
    // wire [4:0] opcode;
    wire [6:0] opcode2;

    wire [4:0] rd, rs1, rs2;
    wire [31:0] rs1_data, rs2_data, rd_data;

    reg [31:0] imm, b;
    // wire funct7;
    wire [31:0] ALU_result, Sum, jalr_target;
    wire [2:0] funct3;
    reg [3:0] ALU_control;

    // D-forwarding
    wire [1:0] ForwardA, ForwardB;
    wire [31:0] rs1_data_forward, rs2_data_forward;
    wire [31:0] ALU_a, ALU_b;

//---------------------------------------//

//---------------------------------------//
    Control control(
            // .opcode(opcode),
            .opcode2(opcode2),
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
            .wen(MEM_WB_RegWrite),
            .rs1(rs1),
            .rs2(rs2),
            .rd(MEM_WB_rd),
            .rs1_data(rs1_data),
            .rs2_data(rs2_data),
            .rd_data(rd_data) // input
            );

    ALU alu(
            .a(ALU_a),
            .b(ALU_b),
            .ALU_control(ALU_control),
            .Zero(Zero),
            .ALU_result(ALU_result)
            );

//---------------------------------------//
    // IF

    // PC
    assign Flush = Branch || Jal || Jalr;
    // assign PC_nxt = (Branch || Jal) ?  Sum :
    //                 Jalr ?  (ALU_a + ID_EX_Imm) & ~32'd1:
    //                 // IF_ID_PC + 32'd4;
    //                 PC + 32'd4;
    assign PC_nxt = (Branch || Jal) ? Sum :
                    Jalr ? jalr_target:
                    PC + 32'd4;

    // assign ICACHE_addr = Flush ? PC_nxt[31:2] : PC[31:2];
    assign ICACHE_addr = PC[31:2];
    assign instruction = {ICACHE_rdata[7:0], ICACHE_rdata[15:8], ICACHE_rdata[23:16], ICACHE_rdata[31:24]};

    assign ICACHE_ren = 1'b1;
    assign ICACHE_wen = 1'b0;
    assign ICACHE_wdata = 32'd0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'd0;
        end
        else if (Flush || !stall) begin
            PC <= PC_nxt;
        end
    end

    // IF/ID reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            IF_ID_Inst <= 32'd0;
        end
        else if (Flush) begin
            IF_ID_Inst <= 32'd0; // NOP for flush
        end
        else if (!stall) begin
            IF_ID_Inst <= instruction;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            IF_ID_PC <= 32'd0;
        end
        else if (Flush) begin
            IF_ID_PC <= 32'd0; // NOP for flush
        end
        else if (!stall) begin
            IF_ID_PC <= PC;
        end
    end

    // ID
    assign opcode = IF_ID_Inst[6:2];
    assign opcode2 = IF_ID_Inst[6:0];
    assign rd = IF_ID_Inst[11:7];
    assign rs1 = IF_ID_Inst[19:15];
    assign rs2 = IF_ID_Inst[24:20];
    assign funct3 = IF_ID_Inst[14:12];

    assign Sum = IF_ID_PC + imm;
    assign jalr_target = (rs1_data_forward + imm) & ~32'd1;
    assign Jal = (IF_ID_Inst[6:2] == 5'b11011);
    assign Jalr = (IF_ID_Inst[6:2] == 5'b11001);
    // assign Branch = (IF_ID_Inst[6:2] == 5'b11000) && 
    //             ((IF_ID_Inst[14:12] == 3'b000 && rs1_data == rs2_data) || // beq
    //             (IF_ID_Inst[14:12] == 3'b001 && rs1_data != rs2_data)); // bne
    assign rs1_data_forward = (EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == rs1) ? EX_MEM_ALU_result :
                          (MEM_WB_RegWrite && MEM_WB_rd != 0 && MEM_WB_rd == rs1) ? rd_data : rs1_data;
    assign rs2_data_forward = (EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == rs2) ? EX_MEM_ALU_result :
                          (MEM_WB_RegWrite && MEM_WB_rd != 0 && MEM_WB_rd == rs2) ? rd_data : rs2_data;
    assign Branch = (IF_ID_Inst[6:2] == 5'b11000) && 
                ((IF_ID_Inst[14:12] == 3'b000 && rs1_data_forward == rs2_data_forward) || 
                 (IF_ID_Inst[14:12] == 3'b001 && rs1_data_forward != rs2_data_forward));

    // ImmGen
    always @(*) begin
        case(opcode2[6:2])
            5'b00000: imm = {{20{IF_ID_Inst[31]}}, IF_ID_Inst[31:20]}; // lw
            5'b11001: imm = {{20{IF_ID_Inst[31]}}, IF_ID_Inst[31:20]}; // jalr
            5'b01000: imm = {{20{IF_ID_Inst[31]}}, IF_ID_Inst[31:25], IF_ID_Inst[11:7]}; // sw
            5'b11000: imm = {{20{IF_ID_Inst[31]}}, IF_ID_Inst[7], IF_ID_Inst[30:25], IF_ID_Inst[11:8], 1'b0}; // beq
            5'b11011: imm = {{12{IF_ID_Inst[31]}}, IF_ID_Inst[19:12], IF_ID_Inst[20], IF_ID_Inst[30:21], 1'b0}; // jal
            5'b00100: imm = {{20{IF_ID_Inst[31]}}, IF_ID_Inst[31:20]}; // I-type
            default: imm = 32'd0; // R-type
        endcase
    end

    // ID/EX reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_PC <= 32'd0;
        // else if (Flush) ID_EX_PC <= PC_nxt;
        else if (Flush && (Jal || Jalr)) ID_EX_PC <= IF_ID_PC;
        else if (!stall) ID_EX_PC <= IF_ID_PC;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_Inst <= 32'd0;
        // else if (Flush) ID_EX_Inst <= 32'd0;
        else if (Flush && (Jal || Jalr)) ID_EX_Inst <= IF_ID_Inst;
        else if (!stall) ID_EX_Inst <= IF_ID_Inst;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_rs1_data <= 32'd0;
        // else if (Flush) ID_EX_rs1_data <= 32'd0;
        else if (!stall) ID_EX_rs1_data <= rs1_data;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_rs2_data <= 32'd0;
        // else if (Flush) ID_EX_rs2_data <= 32'd0;
        else if (!stall) ID_EX_rs2_data <= rs2_data;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_Imm <= 32'd0;
        // else if (Flush) ID_EX_Imm <= 32'd0;
        else if (Flush && (Jal || Jalr)) ID_EX_Imm <= imm;
        else if (!stall) ID_EX_Imm <= imm;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_rd <= 5'd0;
        // else if (Flush) ID_EX_rd <= 5'd0;
        else if (Flush && (Jal || Jalr)) ID_EX_rd <= rd;
        else if (!stall) ID_EX_rd <= rd;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_rs1 <= 5'd0;
        // else if (Flush) ID_EX_rs1 <= 5'd0;
        else if (!stall) ID_EX_rs1 <= rs1;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ID_EX_rs2 <= 5'd0;
        // else if (Flush) ID_EX_rs2 <= 5'd0;
        else if (!stall) ID_EX_rs2 <= rs2;
    end
    always @(posedge clk or negedge rst_n) begin
        // if (!rst_n || Flush || lw_hazard) ID_EX_ALUOp <= 2'd0;
        if (!rst_n || lw_hazard) ID_EX_ALUOp <= 2'd0;
        else if (!stall) ID_EX_ALUOp <= ALUOp;
    end
    always @(posedge clk or negedge rst_n) begin
        // if (!rst_n || Flush || lw_hazard) ID_EX_MemtoReg <= 1'b0;
        if (!rst_n || lw_hazard) ID_EX_MemtoReg <= 1'b0;
        else if (!stall) ID_EX_MemtoReg <= MemtoReg;
    end
    always @(posedge clk or negedge rst_n) begin
        // if (!rst_n || Flush || lw_hazard) ID_EX_MemWrite <= 1'd0;
        if (!rst_n || lw_hazard) ID_EX_MemWrite <= 1'd0;
        else if (!stall) ID_EX_MemWrite <= MemWrite;
    end
    always @(posedge clk or negedge rst_n) begin
        // if (!rst_n || Flush || lw_hazard) ID_EX_ALUSrc <= 1'd0;
        if (!rst_n || lw_hazard) ID_EX_ALUSrc <= 1'd0;
        else if (!stall) ID_EX_ALUSrc <= ALUSrc;
    end
    always @(posedge clk or negedge rst_n) begin
        // if (!rst_n || Flush || lw_hazard) ID_EX_RegWrite <= 1'd0;
        if (!rst_n || lw_hazard) ID_EX_RegWrite <= 1'd0;
        else if (Flush && (Jal || Jalr)) ID_EX_RegWrite <= RegWrite;
        else if (!stall) ID_EX_RegWrite <= RegWrite;
    end

    // EX
    // ALU control
    always @(*) begin
        case(ID_EX_ALUOp)
            2'b00: ALU_control = 4'b0000; // add (lw, sw, jal, jalr)
            2'b01: ALU_control = 4'b0001; // sub (beq, bne)
            2'b10: begin // R-type or I-type
                case(ID_EX_Inst[14:12]) // funct3
                    3'b000: ALU_control = (ID_EX_Inst[6:2] == 5'b01100 && ID_EX_Inst[30]) ? 4'b0001 : 4'b0000; // sub (R-type), add/addi
                    3'b001: ALU_control = 4'b0100; // sll/slli
                    3'b010: ALU_control = 4'b1000; // slt/slti
                    3'b100: ALU_control = 4'b0110; // xor/xori
                    3'b110: ALU_control = 4'b0011; // or/ori
                    3'b111: ALU_control = 4'b0010; // and/andi
                    3'b101: ALU_control = ID_EX_Inst[30] ? 4'b0101 : 4'b0111; // sra/srai, srl/srli
                    default: ALU_control = 4'b1111; // nop
                endcase
            end
            default: ALU_control = 4'b1111; // nop
        endcase
    end

    // Load-Use Hazard
    // assign lw_hazard = ID_EX_MemtoReg && (ID_EX_rd != 0) && (ID_EX_rd == rs1 || ID_EX_rd == rs2);
    assign lw_hazard = ID_EX_MemtoReg && (ID_EX_rd != 0) && (ID_EX_rd == rs1 || ID_EX_rd == ID_EX_rs2);
    // assign lw_hazard = ID_EX_MemtoReg && (ID_EX_rd != 0) && ((ID_EX_rd == rs1) || (ID_EX_rd == rs2)&& (IF_ID_Inst != 32'b0));
    assign stall = ICACHE_stall || DCACHE_stall || lw_hazard;

    // D-forwarding
    assign ForwardA = (EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == ID_EX_rs1) ? 2'b10 :
                    (MEM_WB_RegWrite && MEM_WB_rd != 0 && MEM_WB_rd == ID_EX_rs1 && !(EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == ID_EX_rs1)) ? 2'b01 : 2'b00;
    assign ForwardB = (EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == ID_EX_rs2) ? 2'b10 :
                    (MEM_WB_RegWrite && MEM_WB_rd != 0 && MEM_WB_rd == ID_EX_rs2 && !(EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == ID_EX_rs2)) ? 2'b01 : 2'b00;

    assign ALU_a = (ForwardA == 2'b10) ? EX_MEM_ALU_result :
                (ForwardA == 2'b01) ? rd_data : ID_EX_rs1_data;
    assign ALU_b = ID_EX_ALUSrc ? ID_EX_Imm : 
                (ForwardB == 2'b10) ? EX_MEM_ALU_result :
                (ForwardB == 2'b01) ? rd_data : ID_EX_rs2_data;

    // EX/MEM reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_ALU_result <= 32'd0;
        else if (!stall) EX_MEM_ALU_result <= ALU_result;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_rs2_data <= 32'd0;
        else if (!stall) EX_MEM_rs2_data <= ID_EX_rs2_data;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_rd <= 5'd0;
        else if (!stall) EX_MEM_rd <= ID_EX_rd;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_MemtoReg <= 1'b0;
        else if (!stall) EX_MEM_MemtoReg <= ID_EX_MemtoReg;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_MemWrite <= 1'b0;
        else if (!stall) EX_MEM_MemWrite <= ID_EX_MemWrite;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_RegWrite <= 1'b0;
        else if (!stall) EX_MEM_RegWrite <= ID_EX_RegWrite;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_Zero <= 1'b0;
        else if (!stall) EX_MEM_Zero <= Zero;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_Branch <= 1'b0;
        else if (!stall) EX_MEM_Branch <= Branch;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_Jal <= 1'b0;
        else if (!stall) EX_MEM_Jal <= Jal;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_Jalr <= 1'b0;
        else if (!stall) EX_MEM_Jalr <= Jalr;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_PC_branch <= 32'd0;
        else if (!stall) EX_MEM_PC_branch <= Sum;
    end
    // ************** modified ******************
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) EX_MEM_PC_plus4 <= 32'd0;
        else if (!stall) EX_MEM_PC_plus4 <= ID_EX_PC + 32'd4;
    end
    // *******************************************

    // MEM
    assign DCACHE_ren = EX_MEM_MemtoReg;
    assign DCACHE_wen = EX_MEM_MemWrite;
    assign DCACHE_addr = EX_MEM_ALU_result[31:2];
    assign DCACHE_wdata = {EX_MEM_rs2_data[7:0], EX_MEM_rs2_data[15:8], EX_MEM_rs2_data[23:16], EX_MEM_rs2_data[31:24]};

    // MEM/WB reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_ALU_result <= 32'd0;
        else if (!stall) MEM_WB_ALU_result <= EX_MEM_ALU_result;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_mem_rdata <= 32'd0;
        else if (!stall) MEM_WB_mem_rdata <= {DCACHE_rdata[7:0], DCACHE_rdata[15:8], DCACHE_rdata[23:16], DCACHE_rdata[31:24]};
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_rd <= 5'd0;
        else if (!stall) MEM_WB_rd <= EX_MEM_rd;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_MemtoReg <= 1'b0;
        else if (!stall) MEM_WB_MemtoReg <= EX_MEM_MemtoReg;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_RegWrite <= 1'b0;
        else if (!stall) MEM_WB_RegWrite <= EX_MEM_RegWrite;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_PC_return <= 32'd0;
        // else if (!stall) MEM_WB_PC_return <= ID_EX_PC + 32'd4;
        else if (!stall) MEM_WB_PC_return <= EX_MEM_PC_plus4;  // **************** modified
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_Jal <= 1'b0;
        else if (!stall) MEM_WB_Jal <= EX_MEM_Jal;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) MEM_WB_Jalr <= 1'b0;
        else if (!stall) MEM_WB_Jalr <= EX_MEM_Jalr;
    end

    // WB
    assign rd_data = MEM_WB_MemtoReg ? MEM_WB_mem_rdata :
                    (MEM_WB_Jal || MEM_WB_Jalr) ? MEM_WB_PC_return : 
                     MEM_WB_ALU_result;

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

    assign rs1_data = (rs1 != 0) ? registers[rs1] : 32'd0;
    assign rs2_data = (rs2 != 0) ? registers[rs2] : 32'd0;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <32; i = i+1 ) begin
                registers[i] <= 32'd0;
            end
        end
        else if (wen && (rd != 0)) begin
            registers[rd] <= rd_data;
        end 
    end

endmodule

