module TopModule (
    input  logic       clk,
    input  logic       in,
    input  logic       reset,
    output logic [7:0] out_byte,
    output logic       done
);

    // State definitions
    localparam logic [1:0] STATE_IDLE         = 2'b00;
    localparam logic [1:0] STATE_RECEIVE_DATA = 2'b01;
    localparam logic [1:0] STATE_CHECK_STOP   = 2'b10;
    localparam logic [1:0] STATE_WAIT_STOP    = 2'b11;

    logic [1:0] state;
    logic [2:0] bit_cnt;
    logic [7:0] data_reg;
    logic [7:0] out_byte_reg;
    logic       done_reg;

    // Initialization to avoid X
    initial begin
        state = STATE_IDLE;
        bit_cnt = 3'b0;
        data_reg = 8'b0;
        out_byte_reg = 8'b0;
        done_reg = 1'b0;
    end

    // FSM Sequential Logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            bit_cnt <= 3'b0;
            data_reg <= 8'b0;
            out_byte_reg <= 8'b0;
            done_reg <= 1'b0;
        end else begin
            // Default pulse for done
            done_reg <= 1'b0;

            case (state)
                STATE_IDLE:
                    if (in == 1'b0) begin
                        state <= STATE_RECEIVE_DATA;
                        bit_cnt <= 3'b0;
                        data_reg <= 8'b0;
                    end

                STATE_RECEIVE_DATA:
                    begin
                        // LSB first: first bit received ends up at index 0
                        // Shift left: bit0 becomes bit 7, then bit 6, ..., bit 0
                        data_reg <= {in, data_reg[7:1]};
                        if (bit_cnt == 3'd7) begin
                            state <= STATE_CHECK_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 3'd1;
                        end
                    end

                STATE_CHECK_STOP:
                    if (in == 1'b1) begin
                        state <= STATE_IDLE;
                        done_reg <= 1'b1;
                        out_byte_reg <= data_reg;
                    end else begin
                        state <= STATE_WAIT_STOP;
                    end

                STATE_WAIT_STOP:
                    if (in == 1'b1) begin
                        state <= STATE_IDLE;
                    end else begin
                        state <= STATE_WAIT_STOP;
                    end

                default:
                    state <= STATE_IDLE;
            endcase
        end
    end

    assign out_byte = out_byte_reg;
    assign done     = done_reg;

endmodule