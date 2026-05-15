module TopModule (
    input clk,
    input reset,
    input in,
    output logic done
);

    // Define states
    localparam ST_IDLE   = 3'd0;
    localparam ST_START  = 3'd1;
    localparam ST_DATA   = 3'd2;
    localparam ST_STOP   = 3'd3;

    // State register
    logic [2:0] state;
    logic [2:0] state_next;

    // Counter for data bits
    logic [3:0] bit_count;
    logic [3:0] bit_count_next;

    // Initialize state
    initial begin
        state <= ST_IDLE;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset)
            state <= ST_IDLE;
        else
            state <= state_next;
        
        if (reset)
            bit_count <= 4'd0;
        else
            bit_count <= bit_count_next;
    end

    // Combinational logic for next state and output
    always @(*) begin
        // Default assignments
        state_next = state;
        bit_count_next = bit_count;
        done = 1'b0;

        case (state)
            ST_IDLE: begin
                if (in == 1'b0)
                    state_next = ST_START;
            end
            
            ST_START: begin
                if (in == 1'b1)
                    state_next = ST_IDLE;
                else
                    state_next = ST_DATA;
                bit_count_next = 4'd0;
            end
            
            ST_DATA: begin
                if (bit_count == 4'd7) begin
                    state_next = ST_STOP;
                    bit_count_next = 4'd0;
                end else begin
                    bit_count_next = bit_count + 1;
                    state_next = ST_DATA;
                end
            end
            
            ST_STOP: begin
                if (in == 1'b1) begin
                    state_next = ST_IDLE;
                    done = 1'b1;
                end else begin
                    state_next = ST_IDLE;
                end
            end
        endcase
    end

endmodule