module TopModule (
    input  logic        clk,
    input  logic        reset,
    input  logic [7:0]  in,
    output logic [23:0] out_bytes,
    output logic        done
);

    // State definitions
    localparam STATE_IDLE = 2'b00;
    localparam STATE_B1   = 2'b01; // Captured byte 1
    localparam STATE_B2   = 2'b10; // Captured byte 2
    localparam STATE_B3   = 2'b11; // Captured byte 3

    logic [1:0] state;
    logic [7:0] reg1;
    logic [7:0] reg2;
    logic [7:0] reg3;

    // Sequential logic for FSM and Data storage
    always @(posedge clk) begin
        if (reset) begin
            state    <= STATE_IDLE;
            reg1     <= 8'h0;
            reg2     <= 8'h0;
            reg3     <= 8'h0;
        end else begin
            case (state)
                STATE_IDLE:
                    if (in[3]) begin
                        state <= STATE_B1;
                        reg1  <= in;
                    end else begin
                        state <= STATE_IDLE;
                    end

                STATE_B1:
                    begin
                        state <= STATE_B2;
                        reg2  <= in;
                    end

                STATE_B2:
                    begin
                        state <= STATE_B3;
                        reg3  <= in;
                    end

                STATE_B3:
                    begin
                        // After receiving the 3rd byte, the next cycle 
                        // will trigger the 'done' signal. 
                        // We transition back to IDLE to look for the next start byte.
                        state <= STATE_IDLE;
                        // Check if the byte that just arrived is a new start byte
                        // Actually, the requirement says "discard bytes until we see in[3]=1".
                        // If the 3rd byte itself has in[3]=1, it might be the start of the next message.
                        // However, the FSM usually processes the current sequence first.
                        // Looking at waveform: after done, it goes to IDLE and waits for in[3]=1.
                        // But wait, if the 3rd byte is also a start byte, we need to handle it.
                        // Let's re-examine: the 3rd byte is received in STATE_B2. 
                        // In STATE_B3, we are in the cycle where 'done' is high.
                        if (in[3]) begin
                            state <= STATE_B1;
                            reg1  <= in;
                        end else begin
                            state <= STATE_IDLE;
                        end
                    end

                default:
                    state <= STATE_IDLE;
            endcase
        end
    end

    // Re-evaluating state transitions to match waveform exactly
    // Waveform shows: 
    // Cycle t=45: in=9, done=1, out=2c8109. This is the cycle AFTER 3rd byte (6b) was received.
    // At t=25, in=81 (start byte). t=35, in=9 (2nd byte). t=45, in=6b (3rd byte) -> done=1.
    // Wait, the waveform shows: 
    // t=25: in=81, done=0
    // t=35: in=9,  done=0
    // t=45: in=6b, done=1. (Here 6b is the 3rd byte)
    // This means 'done' is high the same cycle the 3rd byte is 'in'? 
    // No, the description says: "The FSM should signal done in the cycle immediately after the third byte... was successfully received."
    // Let's look at the waveform again:
    // t=25: in=81 (byte 1)
    // t=35: in=9  (byte 2)
    // t=45: in=6b (byte 3), done=1, out=2c8109
    // This implies 'done' and 'out_bytes' are updated at the same time as the 3rd byte is being sampled or immediately after.
    // Actually, in synchronous logic: 
    // T=25: in=81. State becomes B1. reg1=81.
    // T=35: in=9.  State becomes B2. reg2=9. reg1=81.
    // T=45: in=6b. State becomes B3. reg3=6b. reg1=81, reg2=9. done=1. out=2c8109.
    // This means the 'done' signal is logic that depends on the state being B3.

    // Let's refine the FSM logic to be cleaner:
    // IDLE: wait for in[3]==1 -> move to B1, reg1=in
    // B1:   move to B2, reg2=in
    // B2:   move to B3, reg3=in
    // B3:   done=1, out={reg1,reg2,reg3}, move to IDLE (or B1 if in[3]==1)

    // Corrected Sequential Logic:
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            reg1  <= 8'h0;
            reg2  <= 8'h0;
            reg3  <= 8'h0;
        end else begin
            case (state)
                STATE_IDLE:
                    if (in[3]) begin
                        state <= STATE_B1;
                        reg1  <= in;
                    end else begin
                        state <= STATE_IDLE;
                    end
                STATE_B1:
                    begin
                        state <= STATE_B2;
                        reg2  <= in;
                    end
                STATE_B2:
                    begin
                        state <= STATE_B3;
                        reg3  <= in;
                    end
                STATE_B3:
                    begin
                        if (in[3]) begin
                            state <= STATE_B1;
                            reg1  <= in;
                        end else begin
                            state <= STATE_IDLE;
                        end
                    end
                default:
                    state <= STATE_IDLE;
            endcase
        end
    end

    // Combinational logic for outputs
    always @(*) begin
        done = 1'b0;
        out_bytes = 24'h0;
        if (state == STATE_B3) begin
            done = 1'b1;
            out_bytes = {reg1, reg2, reg3};
        end
    end

endmodule