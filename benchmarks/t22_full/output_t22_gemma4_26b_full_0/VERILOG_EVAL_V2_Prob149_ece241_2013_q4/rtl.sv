module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic [2:0] s,
    output logic       fr2,
    output logic       fr1,
    output logic       fr0,
    output logic       dfr
);

    logic [2:0] prev_s;

    // Sequential logic to track the previous sensor state
    always @(posedge clk) begin
        if (reset) begin
            // Reset state: level was low for a long time.
            // The spec says: 'reset the state machine to a state equivalent to if the 
            // water level had been low for a long time (no sensors asserted, and all four outputs asserted)'.
            // To make all outputs 1, we need to set prev_s such that the logic evaluates to 1.
            // Looking at the requirement, the outputs are functions of current s and prev_s.
            // Let's handle the outputs in the combinational block based on a special state or values.
            prev_s <= 3'b000;
        end else begin
            prev_s <= s;
        end
    end

    // Combinational logic for outputs
    always @(*) begin
        // Default values
        fr2 = 1'b0;
        fr1 = 1'b0;
        fr0 = 1'b0;
        dfr = 1'b0;

        if (reset) begin
            // Requirement: 'reset the state machine to a state equivalent to if the 
            // water level had been low for a long time (no sensors asserted, and all four outputs asserted)'.
            fr2 = 1'b1;
            fr1 = 1'b1;
            fr0 = 1'b1;
            dfr = 1'b1;
        end else begin
            // Determine Nominal Flow Rates
            // Above s[2]: s[0], s[1], s[2] are 1 -> s == 3'b111
            if (s == 3'b111) begin
                fr2 = 1'b0;
                fr1 = 1'b0;
                fr0 = 1'b0;
                dfr = 1'b0;
            end 
            // Between s[2] and s[1]: s[0], s[1] are 1 -> s == 3'b011
            else if (s == 3'b011) begin
                fr2 = 1'b0;
                fr1 = 1'b0;
                fr0 = 1'b1;
                // dfr logic will be applied below
            end
            // Between s[1] and s[0]: s[0] is 1 -> s == 3'b001
            else if (s == 3'b001) begin
                fr2 = 1'b0;
                fr1 = 1'b1;
                fr0 = 1'b1;
                // dfr logic will be applied below
            end
            // Below s[0]: None -> s == 3'b000
            else if (s == 3'b000) begin
                fr2 = 1'b1;
                fr1 = 1'b1;
                fr0 = 1'b1;
                // dfr logic will be applied below
            end
            else begin
                // Fallback for undefined states (should not happen per spec)
                fr2 = 1'b0;
                fr1 = 1'b0;
                fr0 = 1'b0;
                dfr = 1'b0;
            end

            // Determine Supplemental flow (dfr)
            // "If the sensor change indicates that the previous level was lower 
            // than the current level, the flow rate should be increased by opening 
            // the Supplemental flow valve (controlled by dfr)."
            // We interpret sensor level by the value of s (since s[2]>s[1]>s[0]).
            // However, s=0, 1, 3, 7 are the valid levels. 
            // If s > prev_s, the level is rising.
            if (s > prev_s) begin
                // Only increase flow if we aren't already at the 'Above s[2]' state
                if (s != 3'b111) begin
                    dfr = 1'b1;
                end else begin
                    dfr = 1'b0;
                end
            end else begin
                dfr = 1'b0;
            end
        end
    end

endmodule