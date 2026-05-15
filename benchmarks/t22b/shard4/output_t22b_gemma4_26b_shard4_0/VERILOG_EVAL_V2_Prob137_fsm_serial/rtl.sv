module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic done
);

    // State definitions
    localparam STATE_IDLE      = 3'd0;
    localparam STATE_DATA      = 3'd1;
    localparam STATE_STOP      = 3'd2;
    localparam STATE_WAIT_STOP = 3'd3;

    // State and counter registers
    logic [2:0] state;
    logic [3:0] bit_cnt;
    logic       done_reg;

    // Initialize to prevent X in simulation
    initial begin
        state    = STATE_IDLE;
        bit_cnt  = 4'd0;
        done_reg = 1'b0;
    end

    // Sequential logic for FSM
    always @(posedge clk) begin
        if (reset) begin
            state    <= STATE_IDLE;
            bit_cnt  <= 4'd0;
            done_reg <= 1'b0;
        end else begin
            // Default values for single-cycle signals
            done_reg <= 1'b0;

            case (state)
                STATE_IDLE:
                    begin
                        if (in == 1'b0) begin
                            state   <= STATE_DATA;
                            bit_cnt <= 4'd0;
                        end else begin
                            state   <= STATE_IDLE;
                        end
                    end

                STATE_DATA:
                    begin
                        if (bit_cnt == 4'd7) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 4'd1;
                            state   <= STATE_DATA;
                        end
                    end

                STATE_STOP:
                    begin
                        if (in == 1'b1) begin
                            done_reg <= 1'b1;
                            state    <= STATE_IDLE;
                        end else begin
                            state    <= STATE_WAIT_STOP;
                        end
                    end

                STATE_WAIT_STOP:
                    begin
                        if (in == 1'b1) begin
                            state <= STATE_IDLE;
                        end else begin
                            state <= STATE_WAIT_STOP;
                        end
                    end

                default:
                    begin
                        state <= STATE_IDLE;
                    end
            endcase
        end
    end

    assign done = done_reg;

endmodule