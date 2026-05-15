module TopModule (
    input clk,
    input reset,
    input [2:0] s,
    output fr2,
    output fr1,
    output fr0,
    output dfr
);

    // Define states based on sensor combinations
    localparam ST_HIGH   = 3'b111; // Above s[2]
    localparam ST_MID2   = 3'b011; // Between s[2] and s[1]
    localparam ST_MID1   = 3'b001; // Between s[1] and s[0]
    localparam ST_LOW    = 3'b000; // Below s[0]

    // Current and next state
    logic [2:0] state;
    logic [2:0] state_next;
    
    // Previous sensor state
    logic [2:0] prev_s;
    
    // Outputs
    logic fr2_out, fr1_out, fr0_out, dfr_out;

    // Sequential logic for state and previous sensor tracking
    always @(posedge clk) begin
        if (reset) begin
            state <= ST_LOW;
            prev_s <= 3'b000;
        end else begin
            state <= state_next;
            prev_s <= s;
        end
    end

    // Next state logic
    always @(*) begin
        case (s)
            ST_HIGH:   state_next = ST_HIGH;
            ST_MID2:   state_next = ST_MID2;
            ST_MID1:   state_next = ST_MID1;
            ST_LOW:    state_next = ST_LOW;
            default:   state_next = ST_LOW;
        endcase
    end

    // Output logic based on current state and previous sensor change
    always @(*) begin
        // Default values
        fr2_out = 1'b1;
        fr1_out = 1'b1;
        fr0_out = 1'b1;
        dfr_out = 1'b0;
        
        // Determine outputs based on current state
        case (state)
            ST_HIGH:
                // No flow needed
                fr2_out = 1'b0;
                fr1_out = 1'b0;
                fr0_out = 1'b0;
            
            ST_MID2:
                // Nominal flow rate fr0
                fr0_out = 1'b0;
                
            ST_MID1:
                // Nominal flow rate fr0, fr1
                fr0_out = 1'b0;
                fr1_out = 1'b0;
                
            ST_LOW:
                // Full flow rate fr0, fr1, fr2
                fr0_out = 1'b0;
                fr1_out = 1'b0;
                fr2_out = 1'b0;
        endcase
        
        // If sensor change indicates water rising, open supplemental valve
        // Simplified logic to detect rising water level
        if ((s[2] >= prev_s[2]) && (s[1] >= prev_s[1]) && (s[0] > prev_s[0]))
            dfr_out = 1'b1;
        else if ((s[2] >= prev_s[2]) && (s[1] > prev_s[1]) && (s[0] <= prev_s[0]))
            dfr_out = 1'b1;
        else if ((s[2] > prev_s[2]) && (s[1] <= prev_s[1]) && (s[0] <= prev_s[0]))
            dfr_out = 1'b1;
    end

    // Assign outputs
    assign fr2 = fr2_out;
    assign fr1 = fr1_out;
    assign fr0 = fr0_out;
    assign dfr = dfr_out;

endmodule