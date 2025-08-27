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
// addr [29:5]tag, [4:2]index, [1:0]block offset
    reg [127:0] block [0:7];
    reg valid [0:7];
    reg dirty [0:7];
    reg [24:0] tag [0:7];

    wire [24:0] tag_t;
    wire [2:0] index; // whcih block
    wire [1:0] offset; // whcih word

    reg [2:0] state, nxt_state;
    wire hit;

    localparam IDLE = 3'b000, CHECK = 3'b001, READ = 3'b010, WRITE = 3'b011, UPDATE = 3'b100;
//==== FSM ================================
    always @(*) begin
        case(state)
            IDLE:    nxt_state = (proc_read || proc_write) ? CHECK : IDLE;
            CHECK:   nxt_state = (hit) ? IDLE : 
                                 (valid[index] && dirty[index]) ? WRITE : READ;
            // READ:    nxt_state = (mem_ready) ? IDLE : READ;
            READ:    nxt_state = (mem_ready) ? (proc_read ? UPDATE : IDLE) : READ;
            WRITE:   nxt_state = (mem_ready) ? READ : WRITE;
            UPDATE:  nxt_state = IDLE;
            default: nxt_state = state;
        endcase
    end

    always@( posedge clk ) begin
        if( proc_reset ) begin
            state <= IDLE;
        end
        else begin 
            state <= nxt_state;
        end
    end
//==== combinational circuit ==============================
    assign tag_t = proc_addr[29:5];
    assign index = proc_addr[4:2];  // whcih block
    assign offset = proc_addr[1:0]; // whcih word

    assign hit = valid[index] && (tag[index] == tag_t);
    assign proc_stall = (nxt_state != IDLE);

    // mem
    assign mem_read = (state == READ);
    assign mem_write = (state == WRITE);
    assign mem_addr = (state == WRITE) ? {tag[index], index} : proc_addr[29:2];
    assign mem_wdata = block[index];
//==== sequential circuit =================================
    integer i;

    always@( posedge clk ) begin
        if( proc_reset ) begin
            for (i = 0; i < 8; i = i+1 ) begin
                valid[i] <= 1'b0;
            end
        end
        else if (state == READ && mem_ready) begin 
            valid[index] <= 1'b1;
        end 
    end

    always@( posedge clk ) begin
        if( proc_reset ) begin
            for (i = 0; i < 8; i = i+1 ) begin
                dirty[i] <= 1'b0;
            end
        end
        else if (proc_write) begin
            if (state == IDLE && hit) dirty[index] <= 1'b1;
            else if (state == READ && mem_ready) dirty[index] <= 1'b1;
        end
        else if (state == WRITE && mem_ready) dirty[index] <= 1'b0;
        // else if (state == IDLE && proc_write && hit) begin 
        //     dirty[index] <= 1'b1;
        // end 
        // else if (state == READ && proc_write && mem_ready) begin 
        //     dirty[index] <= 1'b1;
        // end 
        // else if (state == WRITE && mem_ready) begin
        //     dirty[index] <= 1'b0; 
        // end
    end

    always@( posedge clk ) begin
        if( proc_reset ) begin
            for (i = 0; i < 8; i = i+1 ) begin
                tag[i] <= 25'd0;
            end
        end
        else if (state == READ && mem_ready) tag[index] <= tag_t;
    end

    always@( posedge clk ) begin
        if( proc_reset ) begin
            for (i = 0; i < 8; i = i+1 ) begin
                block[i] <= 128'd0;
            end
        end
        else if (proc_write && (state == IDLE) && hit) begin
            case (offset) // synopsys parallel_case
                2'b00: block[index][31:0] <= proc_wdata;
                2'b01: block[index][63:32] <= proc_wdata;
                2'b10: block[index][95:64] <= proc_wdata;
                2'b11: block[index][127:96] <= proc_wdata;
            endcase            
        end
        else if (state == READ && mem_ready) begin
            // block[index] <= mem_rdata;
            case (offset) // synopsys parallel_case
                2'b00: block[index] <= {mem_rdata[127:32], proc_wdata};
                2'b01: block[index] <= {mem_rdata[127:64], proc_wdata, mem_rdata[31:0]};
                2'b10: block[index] <= {mem_rdata[127:96], proc_wdata, mem_rdata[63:0]};
                2'b11: block[index] <= {proc_wdata, mem_rdata[95:0]};
            endcase
        end
    end

    always@( posedge clk ) begin
        if( proc_reset ) begin
            proc_rdata <= 32'd0;
        end 
        else if (proc_read && (state == IDLE) && hit) begin
            case (offset) // synopsys parallel_case
                2'b00: proc_rdata <= block[index][31:0];
                2'b01: proc_rdata <= block[index][63:32];
                2'b10: proc_rdata <= block[index][95:64];
                2'b11: proc_rdata <= block[index][127:96];
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

endmodule
