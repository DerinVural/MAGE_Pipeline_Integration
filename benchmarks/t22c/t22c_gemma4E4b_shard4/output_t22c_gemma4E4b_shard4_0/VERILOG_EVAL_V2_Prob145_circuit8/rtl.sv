module TopModule (
    input  logic clock,
    input  logic a,
    output logic p,
    output logic q
);

    // Internal state register representing the FSM state, derived from trace analysis.
    // The outputs p and q are driven directly by this state register.
    logic [1:0] state_reg;

    // Initialization: Set state to 00 at simulation start (Time 0ns) as no reset signal is provided.
    initial begin
        state_reg = 2'b00;
    end

    // Sequential logic block to capture state transitions on the positive edge of the clock.
    always @(posedge clock)
    begin
        case (state_reg) 
            // State 00 (p=0, q=0)
            2'b00: begin
                if (a == 1'b1) begin
                    // Transition 00 -> 10 observed at 90ns
                    state_reg <= 2'b10;
                end else begin
                    // Stay in 00 when a=0
                    state_reg <= 2'b00;
                end
            end

            // State 10 (p=1, q=0)
            2'b10: begin
                if (a == 1'b1) begin
                    // Transition 10 -> 11 observed at 110ns
                    state_reg <= 2'b11;
                end else begin
                    // Assuming return to a safe state if a=0 (Not explicitly traced, defaulting to 00 for safety/convergence)
                    state_reg <= 2'b00;
                end
            end

            // State 11 (p=1, q=1)
            2'b11: begin
                if (a == 1'b1) begin
                    // Stay in 11 when a=1
                    state_reg <= 2'b11;
                end else begin
                    // Transition 11 -> 01 observed at 170ns
                    state_reg <= 2'b01;
                end
            end

            // State 01 (p=0, q=1)
            2'b01: begin
                if (a == 1'b1) begin
                    // Transition 01 -> 00 observed at 185ns
                    state_reg <= 2'b00;
                end else begin
                    // Stay in 01 when a=0
                    state_reg <= 2'b01;
                end
            end

            default: begin
                state_reg <= 2'b00; // Safety default
            end
        endcase
    end

    // Assign state registers to outputs (p = state[1], q = state[0] based on trace mapping p=MSB, q=LSB)
    // Trace check: State 10 (p=1, q=0) -> State[1]=1, State[0]=0. This matches p=MSB, q=LSB.
    assign p = state_reg[1];
    assign q = state_reg[0];

endmodule