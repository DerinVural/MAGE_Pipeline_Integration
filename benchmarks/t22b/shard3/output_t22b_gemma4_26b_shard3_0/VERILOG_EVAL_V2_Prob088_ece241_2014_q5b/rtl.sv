module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic x,
    output logic z
);

    // One-hot state encoding
    // state_A: 1'b1, state_B: 1'b0
    // state_B: 1'b0, state_B: 1'b1
    logic state_A;
    logic state_B;

    logic next_state_A;
    logic next_state_B;

    // Initialize signals to avoid X in simulation
    initial begin
        state_A = 1'b1;
        state_B = 1'b0;
    end

    // Sequential logic: State transitions
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state_A <= 1'b1;
            state_B <= 1'b0;
        end else begin
            state_A <= next_state_A;
            state_B <= next_state_B;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state_A = 1'b0;
        next_state_B = 1'b0;

        if (state_A) begin
            if (x) begin
                next_state_B = 1'b1;
                next_state_A = 1'b0;
            end else begin
                next_state_A = 1'b1;
                next_state_B = 1'b0;
            end
        end else if (state_B) begin
            // In state B, we always stay in state B regardless of x
            next_state_B = 1'b1;
            next_state_A = 1'b0;
        end else begin
            // Default to state A to recover from invalid states
            next_state_A = 1'b1;
            next_state_B = 1'b0;
        end
    end

    // Combinational logic: Mealy Output
    // A --x=0 (z=0)--> A
    // A --x=1 (z=1)--> B
    // B --x=0 (z=1)--> B
    // B --x=1 (z=0)--> B
    always @(*) begin
        if (state_A) begin
            z = x; // if x=0, z=0; if x=1, z=1
        end else if (state_B) begin
            z = !x; // if x=0, z=1; if x=1, z=0
        end else begin
            z = 1'b0;
        end
    end

endmodule