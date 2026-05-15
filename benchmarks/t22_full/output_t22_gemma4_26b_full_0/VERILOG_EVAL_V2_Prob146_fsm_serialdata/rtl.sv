module TopModule(
    input  logic clk,
    input  logic in,
    input  logic reset,
    output logic [7:0] out_byte,
    output logic done
);

    // State definitions
    localparam STATE_IDLE         = 3'd0;
    localparam STATE_DATA         = 3'd1;
    localparam STATE_STOP         = 3'd2;
    localparam STATE_ERROR_RECOVERY = 3'd3;

    // State registers
    logic [2:0] state;
    logic [2:0] state_next;

    // Data registers
    logic [7:0] data_reg;
    logic [3:0] bit_cnt;
    logic [7:0] out_byte_reg;
    logic       done_reg;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            data_reg <= 8'b0;
            bit_cnt <= 4'b0;
            out_byte_reg <= 8'b0;
            done_reg <= 1'b0;
        end else begin
            state <= state_next;
            
            // Done signal is a pulse
            done_reg <= 1'b0;

            case (state)
                STATE_IDLE:
                    begin
                        bit_cnt <= 4'b0;
                        data_reg <= 8'b0;
                        if (in == 1'b0) begin
                            // Start bit detected
                            // Note: The spec says start bit is 0. 
                            // The next bit after start bit will be bit 0 of data.
                        end
                    end

                STATE_DATA:
                    begin
                        data_reg[bit_cnt] <= in;
                        bit_cnt <= bit_cnt + 4'd1;
                    end

                STATE_STOP:
                    begin
                        if (in == 1'b1) begin
                            out_byte_reg <= data_reg;
                            done_reg <= 1'b1;
                        end else begin
                            // Framing error: wait for stop bit
                            // The state machine will transition to ERROR_RECOVERY
                        end
                    end

                STATE_ERROR_RECOVERY:
                    begin
                        // Stay here until in == 1
                    end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        state_next = state;
        case (state)
            STATE_IDLE:
                if (in == 1'b0) begin
                    state_next = STATE_DATA;
                end else begin
                    state_next = STATE_IDLE;
                end

            STATE_DATA:
                if (bit_cnt == 4'd7) begin
                    state_next = STATE_STOP;
                end else begin
                    state_next = STATE_DATA;
                end

            STATE_STOP:
                if (in == 1'b1) begin
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_ERROR_RECOVERY;
                end

            STATE_ERROR_RECOVERY:
                if (in == 1'b1) begin
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_ERROR_RECOVERY;
                end
            default:
                state_next = STATE_IDLE;
        endcase
    end

    // Output assignments
    assign out_byte = out_byte_reg;
    assign done = done_reg;

endmodule