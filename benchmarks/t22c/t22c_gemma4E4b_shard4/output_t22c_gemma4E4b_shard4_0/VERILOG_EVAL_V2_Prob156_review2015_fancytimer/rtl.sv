module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    output logic [3:0] count,
    output logic counting,
    output logic done,
    input  logic ack
);

    // --- State Definitions ---
    localparam S_IDLE_SEARCH      = 3'b000;
    localparam S_WAIT_DELAY_BITS   = 3'b001;
    localparam S_COUNTING          = 3'b010;
    localparam S_DONE_WAIT_ACK     = 3'b011;

    // --- Registers ---
    logic [2:0] current_state, next_state;
    logic [3:0] delay_reg; // Stores the 4 bits read after '1101'
    logic [3:0] timer_countdown; // Counts down from delay_reg to 0
    logic [1:0] pattern_match_state; // Tracks sequence for 1101 (00=None, 01=1, 10=11, 11=110)
    logic [1:0] bit_counter; // Counter for 4 bits in WAIT_DELAY_BITS phase

    // --- Initial Value Assignments ---
    initial begin
        // Initialize all non-reset logic to a known safe state
        current_state = S_IDLE_SEARCH;
        delay_reg = 4'b0000;
        timer_countdown = 4'b0000;
        pattern_match_state = 2'b00;
        bit_counter = 2'b00;
    end

    // --- State Register Logic (Sequential) ---
    always @(posedge clk)
    begin
        if (reset)
        begin
            current_state <= S_IDLE_SEARCH;
            pattern_match_state <= 2'b00;
            timer_countdown <= 4'b0000;
            delay_reg <= 4'b0000;
            bit_counter <= 2'b00;
        end else begin
            current_state <= next_state;

            // Reset auxiliary trackers based on the NEXT state to ensure clean state entry
            case (next_state) 
                S_IDLE_SEARCH: begin
                    pattern_match_state <= 2'b00;
                    bit_counter <= 2'b00;
                end
                S_WAIT_DELAY_BITS: begin
                    bit_counter <= 2'b00;
                end
                S_COUNTING: begin
                    // Timer countdown is updated separately in the clock block
                end
                S_DONE_WAIT_ACK: begin
                    // Hold state
                end
            endcase
        end
    end

    // --- Pattern Matching Logic (Combinational) ---
    always @(*)
    begin
        // Only track pattern if in the search state
        if (current_state == S_IDLE_SEARCH) begin
            case (pattern_match_state) 
                2'b00: begin
                    if (data == 1'b1) pattern_match_state = 2'b01; 
                    else pattern_match_state = 2'b00;
                end
                2'b01: begin // Saw '1'
                    if (data == 1'b1) pattern_match_state = 2'b10; 
                    else pattern_match_state = 2'b00;
                end
                2'b10: begin // Saw '11'
                    if (data == 1'b0) pattern_match_state = 2'b11; 
                    else pattern_match_state = 2'b01;
                end
                2'b11: begin // Saw '110'
                    if (data == 1'b1) pattern_match_state = 2'b11; // Found '1101'
                    else pattern_match_state = 2'b00;
                end
                default: pattern_match_state = 2'b00;
            endcase
        end
    end

    // --- Next State Logic (Combinational) ---
    always @(*)
    begin
        next_state = current_state;
        
        case (current_state) 
            S_IDLE_SEARCH:
                if (pattern_match_state == 2'b11 && data == 1'b1) begin // Detected 1101
                    next_state = S_WAIT_DELAY_BITS;
                end

            S_WAIT_DELAY_BITS:
                // Transition after 4 bits have been captured (bit_counter reaches 2'b11)
                if (bit_counter == 2'b11) begin 
                    next_state = S_COUNTING;
                end

            S_COUNTING:
                if (timer_countdown == 4'b0000) begin
                    next_state = S_DONE_WAIT_ACK;
                end

            S_DONE_WAIT_ACK:
                if (ack == 1'b1) begin
                    next_state = S_IDLE_SEARCH;
                end
        endcase
    end

    // --- Output Logic (Combinational) ---
    always @(*)
    begin
        count = 4'b0;
        counting = 1'b0;
        done = 1'b0;

        case (current_state) 
            S_IDLE_SEARCH:
                // Don't care
                count = 4'b0;
                counting = 1'b0;
                done = 1'b0;

            S_WAIT_DELAY_BITS:
                // Don't care
                count = 4'b0;
                counting = 1'b0;
                done = 1'b0;

            S_COUNTING:
                counting = 1'b1;
                done = 1'b0;
                // Output reflects the remaining delay value
                count = timer_countdown;

            S_DONE_WAIT_ACK:
                counting = 1'b0;
                done = 1'b1;
                // Don't care
                count = 4'b0;
        endcase
    end

    // --- Sequential Logic for Data Capture and Timer Update ---
    always @(posedge clk)
    begin
        if (reset) begin
            // Reset handled in initial block for initialization, but safety reset here
            delay_reg <= 4'b0000;
            timer_countdown <= 4'b0000;
            bit_counter <= 2'b00;
        end else begin

            // 1. Data Capture in WAIT_DELAY_BITS state
            if (current_state == S_WAIT_DELAY_BITS) begin
                // Load data based on bit_counter (00=MSB, 11=LSB)
                case (bit_counter) 
                    2'b00: delay_reg[3] <= data; // MSB
                    2'b01: delay_reg[2] <= data;
                    2'b10: delay_reg[1] <= data;
                    2'b11: delay_reg[0] <= data; // LSB
                    default: ; 
                endcase
                // Increment bit counter for next cycle
                bit_counter <= bit_counter + 1'b1;
            end

            // 2. Timer Countdown in COUNTING state
            if (current_state == S_COUNTING) begin
                if (timer_countdown > 4'b0000) begin
                    timer_countdown <= timer_countdown - 1'b1;
                end
            end

            // 3. Initial Timer Load (Triggered only on the cycle *after* the 4th bit is captured)
            if (current_state == S_WAIT_DELAY_BITS && next_state == S_COUNTING) begin
                // Initialize the countdown to the captured delay value
                timer_countdown <= delay_reg;
            end
        end
    end

endmodule