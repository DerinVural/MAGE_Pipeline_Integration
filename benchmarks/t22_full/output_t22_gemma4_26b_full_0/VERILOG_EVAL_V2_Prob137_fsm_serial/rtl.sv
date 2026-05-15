module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic done
);

    // State definitions
    localparam STATE_IDLE     = 3'b000;
    localparam STATE_DATA     = 3'b001;
    localparam STATE_STOP     = 3'b010;
    localparam STATE_RECOVERY = 3'b011;

    // State and counter registers
    logic [2:0] state;
    logic [3:0] bit_count;

    // Initialize state to avoid X
    initial begin
        state = STATE_IDLE;
        bit_count = 4'd0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            bit_count <= 4'd0;
        end else begin
            case (state)
                STATE_IDLE:
                    if (in == 1'b0) begin
                        state <= STATE_DATA;
                        bit_count <= 4'd0;
                    end else begin
                        state <= STATE_IDLE;
                    end

                STATE_DATA:
                    if (bit_count == 4'd7) begin
                        state <= STATE_STOP;
                        bit_count <= 4'd0;
                    end else begin
                        bit_count <= bit_count + 4'd1;
                        state <= STATE_DATA;
                    end

                STATE_STOP:
                    if (in == 1'b1) begin
                        state <= STATE_IDLE;
                    end else begin
                        state <= STATE_RECOVERY;
                    end

                STATE_RECOVERY:
                    if (in == 1'b1) begin
                        state <= STATE_IDLE;
                    end else begin
                        state <= STATE_RECOVERY;
                    end

                default:
                    state <= STATE_IDLE;
            endcase
        end
    end

    // Output logic
    // 'done' should be high for one cycle when the stop bit is correctly identified.
    // The stop bit is checked in STATE_STOP. If in == 1, we transition to IDLE.
    // To pulse 'done' exactly when the stop bit is verified:
    always @(*) begin
        done = 1'b0;
        if (state == STATE_STOP && in == 1'b1) begin
            done = 1'b1;
        end
    end

endmodule