module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    output logic       done
);

    // State definitions
    localparam ST_SEARCH = 2'd0;
    localparam ST_BYTE2  = 2'd1;
    localparam ST_BYTE3  = 2'd2;
    localparam ST_DONE   = 2'd3;

    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_SEARCH;
        end else begin
            state <= state_next;
        end
    end

    // Next state combinational logic
    always @(*) begin
        state_next = state;
        case (state)
            ST_SEARCH: begin
                if (in[3] == 1'b1) begin
                    state_next = ST_BYTE2;
                end else begin
                    state_next = ST_SEARCH;
                end
            end
            ST_BYTE2: begin
                state_next = ST_BYTE3;
            end
            ST_BYTE3: begin
                state_next = ST_DONE;
            end
            ST_DONE: begin
                // After signaling done, we must check if the current byte is a start of a new message
                if (in[3] == 1'b1) begin
                    state_next = ST_BYTE2;
                end else begin
                    state_next = ST_SEARCH;
                end
            end
            default: begin
                state_next = ST_SEARCH;
            end
        endcase
    end

    // Output combinational logic
    always @(*) begin
        if (state == ST_DONE) begin
            done = 1'b1;
        end else begin
            done = 1'b0;
        end
    end

endmodule