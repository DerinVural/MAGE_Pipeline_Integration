module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    output logic start_shifting
);

    // State Encoding (Need 5 states: 000 to 100 -> 3 bits)
    localparam S_IDLE          = 3'b000; // Waiting for 1
    localparam S_ONE           = 3'b001; // Seen '1'
    localparam S_ONE_ONE       = 3'b010; // Seen '11'
    localparam S_ONE_ONE_ZERO  = 3'b011; // Seen '110'
    localparam S_FOUND         = 3'b100; // Found '1101' (Sticky state)

    // State Registers
    logic [2:0] state;
    logic [2:0] next_state;

    // 1. State Register Logic (Sequential - Clocked and Synchronous Reset)
    always @(posedge clk, posedge reset)
    begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // 2. Next State Logic (Combinational)
    always @(*)
    begin
        next_state = state;

        case (state)
            S_IDLE:
                if (data == 1'b1) next_state = S_ONE;
                else next_state = S_IDLE;

            S_ONE:
                if (data == 1'b1) next_state = S_ONE_ONE;
                else next_state = S_IDLE; // Sequence broken

            S_ONE_ONE:
                if (data == 1'b0) next_state = S_ONE_ONE_ZERO;
                else next_state = S_ONE_ONE; // Stay in S_ONE_ONE if input is 1 (e.g., 11 -> 111)

            S_ONE_ONE_ZERO:
                if (data == 1'b1) next_state = S_FOUND; // Sequence 1101 found!
                else next_state = S_IDLE; // Sequence broken (e.g., 1100)

            S_FOUND:
                next_state = S_FOUND; // Stay found (Sticky)
        endcase
    end

    // 3. Output Logic (Registered to maintain '1' until reset)
    // The output is asserted whenever the current state is S_FOUND.
    always @(posedge clk, posedge reset)
    begin
        if (reset)
            start_shifting <= 1'b0;
        else
            start_shifting <= (state == S_FOUND) ? 1'b1 : 1'b0;
    end

endmodule