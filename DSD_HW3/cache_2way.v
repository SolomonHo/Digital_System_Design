module cache(
    clk,
    proc_reset,
    proc_read,
    proc_write,
    proc_addr,
    proc_rdata,
    proc_wdata,
    proc_stall,
    mem_read,
    mem_write,
    mem_addr,
    mem_rdata,
    mem_wdata,
    mem_ready
);
    
//==== input/output definition ============================
    input          clk;
    // processor interface
    input          proc_reset;
    input          proc_read, proc_write;
    input   [29:0] proc_addr;  // 2 bits offset
    input   [31:0] proc_wdata;
    output         proc_stall;
    output reg [31:0] proc_rdata;
    // memory interface
    input  [127:0] mem_rdata;
    input          mem_ready;
    output         mem_read, mem_write;
    output  [27:0] mem_addr;
    output [127:0] mem_wdata;
    
//==== wire/reg definition ================================
// addr [29:4]tag, [3:2]index, [1:0]block offset
    reg [127:0] block0 [0:3]; 
    reg [127:0] block1 [0:3]; 
    reg valid0 [0:3];        
    reg valid1 [0:3];       
    reg dirty0 [0:3];        
    reg dirty1 [0:3];         
    reg [25:0] tag0 [0:3];   
    reg [25:0] tag1 [0:3];   
    reg LRU [0:3];            // LRU bits (1: way 1 MRU, 0: way 0 MRU)

    wire [25:0] tag_t;       
    wire [1:0] index;        
    wire [1:0] offset;     
    wire hit0, hit1, hit;   
    wire replace_way;         // Way to replace (0: way 0, 1: way 1)

    reg [2:0] state, nxt_state;
    reg replace_way_reg;     

    localparam IDLE = 3'b000, CHECK = 3'b001, READ = 3'b010, WRITE = 3'b011, UPDATE = 3'b100;

//==== FSM ================================
    always @(*) begin
        case(state)
            IDLE:    nxt_state = (proc_read || proc_write) ? CHECK : IDLE;
            CHECK:   nxt_state = hit ? IDLE : 
                                 (replace_way ? (valid1[index] && dirty1[index]) : 
                                                (valid0[index] && dirty0[index])) ? WRITE : READ;
            READ:    nxt_state = (mem_ready) ? (proc_read ? UPDATE : IDLE) : READ;
            WRITE:   nxt_state = (mem_ready) ? READ : WRITE;
            UPDATE:  nxt_state = IDLE;
            default: nxt_state = state;
        endcase
    end

    always @(posedge clk) begin
        if (proc_reset) begin
            state <= IDLE;
        end
        else begin 
            state <= nxt_state;
        end
    end

//==== combinational circuit ==============================
    assign tag_t = proc_addr[29:4];    
    assign index = proc_addr[3:2];      
    assign offset = proc_addr[1:0];   

    assign hit0 = valid0[index] && (tag0[index] == tag_t); 
    assign hit1 = valid1[index] && (tag1[index] == tag_t); 
    assign hit = hit0 || hit1;                           
    assign proc_stall = (nxt_state != IDLE);

    assign replace_way = LRU[index]; // 1: replace way 1, 0: replace way 0

    assign mem_read = (state == READ);
    assign mem_write = (state == WRITE);
    assign mem_addr = (state == WRITE) ? 
                      (replace_way_reg ? {tag1[index], index} : {tag0[index], index}) : 
                      proc_addr[29:2];
    assign mem_wdata = replace_way_reg ? block1[index] : block0[index];

//==== sequential circuit =================================
    integer i;

    always @(posedge clk) begin
        if (proc_reset) begin
            for (i = 0; i < 4; i = i+1) begin
                valid0[i] <= 1'b0;
                valid1[i] <= 1'b0;
            end
        end
        else if (state == READ && mem_ready) begin 
            if (replace_way_reg) valid1[index] <= 1'b1;
            else valid0[index] <= 1'b1;
        end 
    end

    always @(posedge clk) begin
        if (proc_reset) begin
            for (i = 0; i < 4; i = i+1) begin
                dirty0[i] <= 1'b0;
                dirty1[i] <= 1'b0;
            end
        end
        else if (proc_write) begin
            if (state == IDLE && hit0) dirty0[index] <= 1'b1;
            else if (state == IDLE && hit1) dirty1[index] <= 1'b1;
            else if (state == READ && mem_ready) begin
                if (replace_way_reg) dirty1[index] <= 1'b1;
                else dirty0[index] <= 1'b1;
            end
        end
        else if (state == WRITE && mem_ready) begin
            if (replace_way_reg) dirty1[index] <= 1'b0;
            else dirty0[index] <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (proc_reset) begin
            for (i = 0; i < 4; i = i+1) begin
                tag0[i] <= 26'd0;
                tag1[i] <= 26'd0;
            end
        end
        else if (state == READ && mem_ready) begin
            if (replace_way_reg) tag1[index] <= tag_t;
            else tag0[index] <= tag_t;
        end
    end

    always @(posedge clk) begin
        if (proc_reset) begin
            for (i = 0; i < 4; i = i+1) begin
                LRU[i] <= 1'b0;
            end
        end
        else if (state == CHECK && hit) begin
            LRU[index] <= hit1 ? 1'b1 : 1'b0; 
        end
        else if (state == READ && mem_ready) begin
            LRU[index] <= replace_way_reg ? 1'b1 : 1'b0; 
        end
    end

    // always @(posedge clk) begin
    //     if (proc_reset) begin
    //         for (i = 0; i < 4; i = i+1) begin
    //             block0[i] <= 128'd0;
    //             block1[i] <= 128'd0;
    //         end
    //     end
    //     else if (proc_write && state == IDLE && hit) begin
    //         if (hit0) begin
    //             case (offset) // synopsys parallel_case
    //                 2'b00: block0[index][31:0] <= proc_wdata;
    //                 2'b01: block0[index][63:32] <= proc_wdata;
    //                 2'b10: block0[index][95:64] <= proc_wdata;
    //                 2'b11: block0[index][127:96] <= proc_wdata;
    //             endcase
    //         end
    //         else if (hit1) begin
    //             case (offset) // synopsys parallel_case
    //                 2'b00: block1[index][31:0] <= proc_wdata;
    //                 2'b01: block1[index][63:32] <= proc_wdata;
    //                 2'b10: block1[index][95:64] <= proc_wdata;
    //                 2'b11: block1[index][127:96] <= proc_wdata;
    //             endcase
    //         end
    //     end
    //     else if (state == READ && mem_ready) begin
    //         if (proc_write) begin
    //             case (offset) // synopsys parallel_case
    //                 2'b00: begin
    //                     if (replace_way_reg) block1[index] <= {mem_rdata[127:32], proc_wdata};
    //                     else block0[index] <= {mem_rdata[127:32], proc_wdata};
    //                 end
    //                 2'b01: begin
    //                     if (replace_way_reg) block1[index] <= {mem_rdata[127:64], proc_wdata, mem_rdata[31:0]};
    //                     else block0[index] <= {mem_rdata[127:64], proc_wdata, mem_rdata[31:0]};
    //                 end
    //                 2'b10: begin
    //                     if (replace_way_reg) block1[index] <= {mem_rdata[127:96], proc_wdata, mem_rdata[63:0]};
    //                     else block0[index] <= {mem_rdata[127:96], proc_wdata, mem_rdata[63:0]};
    //                 end
    //                 2'b11: begin
    //                     if (replace_way_reg) block1[index] <= {proc_wdata, mem_rdata[95:0]};
    //                     else block0[index] <= {proc_wdata, mem_rdata[95:0]};
    //                 end
    //             endcase
    //         end
    //         else begin
    //             if (replace_way_reg) block1[index] <= mem_rdata;
    //             else block0[index] <= mem_rdata;
    //         end
    //     end
    // end
    always @(posedge clk) begin
        if (proc_reset) begin
            for (i = 0; i < 4; i = i+1) begin
                block0[i] <= 128'd0;
            end
        end
        else if (proc_write && state == IDLE && hit0) begin
            case (offset) // synopsys parallel_case
                2'b00: block0[index][31:0] <= proc_wdata;
                2'b01: block0[index][63:32] <= proc_wdata;
                2'b10: block0[index][95:64] <= proc_wdata;
                2'b11: block0[index][127:96] <= proc_wdata;
            endcase
         end
        else if (state == READ && mem_ready && !replace_way_reg) begin
            if (proc_write) begin
                case (offset) // synopsys parallel_case
                    2'b00: block0[index] <= {mem_rdata[127:32], proc_wdata};
                    2'b01: block0[index] <= {mem_rdata[127:64], proc_wdata, mem_rdata[31:0]};
                    2'b10: block0[index] <= {mem_rdata[127:96], proc_wdata, mem_rdata[63:0]};
                    2'b11: block0[index] <= {proc_wdata, mem_rdata[95:0]};
                endcase
            end
            else begin
                block0[index] <= mem_rdata;
            end
        end
    end

    always @(posedge clk) begin
        if (proc_reset) begin
            for (i = 0; i < 4; i = i+1) begin
                block1[i] <= 128'd0;
            end
        end
        else if (proc_write && state == IDLE && hit1) begin
            case (offset) // synopsys parallel_case
                2'b00: block1[index][31:0] <= proc_wdata;
                2'b01: block1[index][63:32] <= proc_wdata;
                2'b10: block1[index][95:64] <= proc_wdata;
                2'b11: block1[index][127:96] <= proc_wdata;
            endcase
        end
        else if (state == READ && mem_ready && replace_way_reg) begin
            if (proc_write) begin
                case (offset) // synopsys parallel_case
                    2'b00: block1[index] <= {mem_rdata[127:32], proc_wdata};
                    2'b01: block1[index] <= {mem_rdata[127:64], proc_wdata, mem_rdata[31:0]};
                    2'b10: block1[index] <= {mem_rdata[127:96], proc_wdata, mem_rdata[63:0]};
                    2'b11: block1[index] <= {proc_wdata, mem_rdata[95:0]};
                endcase
            end
            else begin
                block1[index] <= mem_rdata;
            end
        end
    end
    
    always @(posedge clk) begin
        if (proc_reset) begin
            proc_rdata <= 32'd0;
        end 
        else if (proc_read && state == IDLE && hit) begin
            case (offset) // synopsys parallel_case
                2'b00: proc_rdata <= hit0 ? block0[index][31:0] : block1[index][31:0];
                2'b01: proc_rdata <= hit0 ? block0[index][63:32] : block1[index][63:32];
                2'b10: proc_rdata <= hit0 ? block0[index][95:64] : block1[index][95:64];
                2'b11: proc_rdata <= hit0 ? block0[index][127:96] : block1[index][127:96];
            endcase
        end
        else if (state == READ && mem_ready && proc_read) begin
            case (offset) // synopsys parallel_case
                2'b00: proc_rdata <= mem_rdata[31:0];
                2'b01: proc_rdata <= mem_rdata[63:32];
                2'b10: proc_rdata <= mem_rdata[95:64];
                2'b11: proc_rdata <= mem_rdata[127:96];
            endcase
        end
    end

    always @(posedge clk) begin
        if (proc_reset) begin
            replace_way_reg <= 1'b0;
        end
        else if (state == CHECK && !hit) begin
            replace_way_reg <= replace_way;
        end
    end

endmodule