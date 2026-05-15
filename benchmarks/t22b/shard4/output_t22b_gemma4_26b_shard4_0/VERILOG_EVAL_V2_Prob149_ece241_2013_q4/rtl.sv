module TopModule (
    input  logic       clk,
    input  logic       reset,
    input  logic [2:0] s,
    output logic       fr2,
    output logic       fr1,
    output logic       fr0,
    output logic       dfr
);

    logic [2:0] prev_s;

    // Initialize prev_s to 0 to avoid X in simulation
    initial begin
        prev_s = 3'b000;
    end

    // Sequential logic to track the previous sensor state
    always @(posedge clk) begin
        if (reset) begin
            prev_s <= 3'b000;
        end else begin
            prev_s <= s;
        end
    end

    // Combinational logic for flow rates and supplemental flow
    always @(*) begin
        // Default values
        fr2 = 1'b0;
        fr1 = 1'b0;
        fr0 = 1'b0;
        dfr = 1'b0;

        // Determine Nominal Flow Rates based on sensor pattern
        // Note: s[2] is highest, s[0] is lowest.
        // Pattern 's[0], s[1], s[2]' means s=3'b111
        // Pattern 's[0], s[1]' means s=3'b011
        // Pattern 's[0]' means s=3'b001
        // Pattern 'None' means s=3'b000

        case (s) 
            3'b111: begin
                // Above s[2]: None
                fr2 = 1'b0;
                fr1 = 1'b0;
                fr0 = 1'b0;
            end
            3'b011: begin
                // Between s[2] and s[1]: fr0
                fr0 = 1'b1;
            end
            3'b001: begin
                // Between s[1] and s[0]: fr0, fr1
                fr0 = 1'b1;
                fr1 = 1'b1;
            end
            3'b000: begin
                // Below s[0]: fr0, fr1, fr2
                fr0 = 1'b1;
                fr1 = 1'b1;
                fr2 = 1'b1;
            end
            default: begin
                // For intermediate/undefined sensor states not explicitly in table
                // We treat them as 0 flow unless they match the pattern logic
                fr2 = 1'b0;
                fr1 = 1'b0;
                fr0 = 1'b0;
            end
        endcase

        // Supplemental flow (dfr) logic
        // "If the sensor change indicates that the previous level was lower than the current level"
        // Higher level corresponds to more bits set in 's' (e.g., 3'b011 > 3'b001)
        // We check if the current sensor value 's' is numerically greater than 'prev_s'
        // but only if a change actually occurred.
        if (s != prev_s && s > prev_s) begin
            dfr = 1'b1;
        end else begin
            dfr = 1'b0;
        end

        // Handle Synchronous Reset Output state
        // Requirement: "reset the state machine to a state equivalent to if the water level 
        // had been low for a long time (no sensors asserted, and all four outputs asserted)."
        if (reset) begin
            fr2 = 1'b1;
            fr1 = 1'b1;
            fr0 = 1'b1;
            dfr = 1'b1;
        end
    end

endmodule