module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    output logic [23:0] out_bytes,
    output logic       done
);

    // State definitions
    localparam STATE_SEARCH    = 3'd0;
    localparam STATE_BYTE2     = 3'd1;
    localparam STATE_BYTE3     = 3'd2;
    localparam STATE_DONE      = 3'd3;

    // State register
    logic [2:0] state;
    
    // Data registers
    logic [7:0] b1, b2, b3;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_SEARCH;
            b1 <= 8'h0;
            b2 <= 8'h0;
            b3 <= 8'h0;
        end else begin
            case (state)
                STATE_SEARCH:
                    if (in[3] == 1'b1) begin
                        b1 <= in;
                        state <= STATE_BYTE2;
                    end else begin
                        state <= STATE_SEARCH;
                    end

                STATE_BYTE2:
                    begin
                        b2 <= in;
                        state <= STATE_BYTE3;
                    end

                STATE_BYTE3:
                    begin
                        b3 <= in;
                        state <= STATE_DONE;
                    end

                STATE_DONE:
                    begin
                        // After signaling done, we check if the current 'in' (which was the 3rd byte)
                        // is actually the start of a new message. 
                        // Wait, the waveform shows 'done' is asserted the cycle AFTER the 3rd byte is received.
                        // In the waveform: 
                        // Cycle N: in=09 (3rd byte), done=0, out=0
                        // Cycle N+1: in=d  (next byte), done=1, out=2c8109
                        // This means the 3rd byte is latched, then in the NEXT cycle, 'done' is high.
                        // Let's re-evaluate.
                        state <= STATE_SEARCH; // This will be handled by the transition logic below
                    end
                
                default:
                    state <= STATE_SEARCH;
            endcase
        end
    end

    // Refined FSM for the specific 'done' timing in waveform
    // The waveform shows: 
    // Byte 1: in=2c (in[3]=1) -> state changes
    // Byte 2: in=81 -> state changes
    // Byte 3: in=09 -> state changes to DONE, and in the NEXT cycle done=1.
    // However, in the next cycle, the 'in' is the new byte 'd'.
    // So the transition from DONE to SEARCH must happen simultaneously with checking the NEW 'in'.

    // Let's use a simpler state machine logic to match the waveform exactly.
    // State 0: Searching for in[3]==1
    // State 1: Just received Byte 1, waiting for Byte 2
    // State 2: Just received Byte 2, waiting for Byte 3
    // State 3: Just received Byte 3, signaling DONE

    // Resetting the logic above to follow the pattern.
    // We will use a single always block for the FSM to ensure clean transitions.

    logic [2:0] state_reg;
    logic [7:0] r1, r2, r3;

    always @(posedge clk) begin
        if (reset) begin
            state_reg <= STATE_SEARCH;
            r1 <= 8'h0;
            r2 <= 8'h0;
            r3 <= 8'h0;
        end else begin
            case (state_reg)
                STATE_SEARCH:
                    if (in[3] == 1'b1) begin
                        r1 <= in;
                        state_reg <= STATE_BYTE2;
                    end else begin
                        state_reg <= STATE_SEARCH;
                    end

                STATE_BYTE2:
                    begin
                        r2 <= in;
                        state_reg <= STATE_BYTE3;
                    end

                STATE_BYTE3:
                    begin
                        r3 <= in;
                        state_reg <= STATE_DONE;
                    end

                STATE_DONE:
                    begin
                        // In the cycle we are in STATE_DONE, we are looking at the new 'in'.
                        // If the new 'in' has in[3]==1, we start a new sequence.
                        if (in[3] == 1'b1) begin
                            r1 <= in;
                            state_reg <= STATE_BYTE2;
                        end else begin
                            state_reg <= STATE_SEARCH;
                        end
                    end
                default:
                    state_reg <= STATE_SEARCH;
            endcase
        end
    end

    // Combinational outputs
    always @(*) begin
        done = 1'b0;
        out_bytes = 24'h0;
        if (state_reg == STATE_DONE) begin
            done = 1'b1;
            out_bytes = {r1, r2, r3};
        end
    end

endmodule