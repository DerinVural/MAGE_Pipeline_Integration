module TopModule (
    input logic clk,
    input logic reset,
    input logic [2:0] s,
    output logic fr2,
    output logic fr1,
    output logic fr0,
    output logic dfr
);

    // State encoding reflecting water level order: 0 (Lowest) -> 3 (Highest)
    localparam STATE_LOW    = 2'b00; // s=0
    localparam STATE_MID_LOW = 2'b01; // s=1
    localparam STATE_MID_UP = 2'b10; // s=3
    localparam STATE_HIGH   = 2'b11; // s=7

    // State registers
    logic [1:0] state;
    logic [1:0] state_next;

    // Initialize state registers to a known value before clocking starts (Requirement 3)
    initial begin
        state = STATE_LOW;
        state_next = STATE_LOW;
    end

    // --- 1. Sequential Logic (State Update) ---
    always @(posedge clk)
    begin
        if (reset)
            state <= STATE_LOW; // Reset to lowest level state
        else
            state <= state_next;
    end

    // --- 2. Next State Combinational Logic ---
    always @(*)
    begin
        state_next = state;

        case (state)
            STATE_LOW:
                case (s) 
                    3'b000: state_next = STATE_LOW;        // Below s[0] -> Stay Low
                    3'b001: state_next = STATE_MID_LOW;   // s[0] asserted -> Move to MidLow
                    3'b011: state_next = STATE_MID_UP;    // s[0], s[1] asserted -> Move to MidUp
                    3'b111: state_next = STATE_HIGH;      // s[0], s[1], s[2] asserted -> Move to High
                    default: state_next = STATE_LOW;      // Default to low
                endcase

            STATE_MID_LOW:
                case (s) 
                    3'b000: state_next = STATE_LOW;        // Level dropped below s[0]
                    3'b001: state_next = STATE_MID_LOW;   // Stay MidLow
                    3'b011: state_next = STATE_MID_UP;    // Level rose to MidUp
                    3'b111: state_next = STATE_HIGH;      // Level rose to High
                    default: state_next = STATE_MID_LOW; 
                endcase

            STATE_MID_UP:
                case (s) 
                    3'b000: state_next = STATE_LOW;        // Level dropped below s[0]
                    3'b001: state_next = STATE_MID_LOW;   // Level dropped to MidLow
                    3'b011: state_next = STATE_MID_UP;    // Stay MidUp
                    3'b111: state_next = STATE_HIGH;      // Level rose to High
                    default: state_next = STATE_MID_UP; 
                endcase

            STATE_HIGH:
                case (s) 
                    3'b000: state_next = STATE_LOW;        // Level dropped below s[0]
                    3'b001: state_next = STATE_MID_LOW;   // Level dropped to MidLow
                    3'b011: state_next = STATE_MID_UP;    // Level dropped to MidUp
                    3'b111: state_next = STATE_HIGH;      // Stay High
                    default: state_next = STATE_HIGH; 
                endcase

        endcase
    end

    // --- 3. Output Logic (Combinational) ---
    // Nominal Flow Rates (fr2, fr1, fr0)
    always @(*)
    begin
        // Default values
        fr2 = 1'b0;
        fr1 = 1'b0;
        fr0 = 1'b0;

        case (state)
            STATE_HIGH:
                // Above s[2] -> None
                fr2 = 1'b0;
                fr1 = 1'b0;
                fr0 = 1'b0;

            STATE_MID_UP:
                // Between s[2] and s[1] -> fr0
                fr2 = 1'b0;
                fr1 = 1'b0;
                fr0 = 1'b1;

            STATE_MID_LOW:
                // Between s[1] and s[0] -> fr0, fr1
                fr2 = 1'b0;
                fr1 = 1'b1;
                fr0 = 1'b1;

            STATE_LOW:
                // Below s[0] -> fr0, fr1, fr2
                fr2 = 1'b1;
                fr1 = 1'b1;
                fr0 = 1'b1;
        endcase
    end

    // Supplemental Flow Valve (dfr) Logic: 1 if level is rising (Next State > Current State)
    always @(*)
    begin
        dfr = 1'b0;
        
        // Level is rising if the next state numerically represents a higher level regime
        if (state_next > state)
            dfr = 1'b1;
    end

endmodule