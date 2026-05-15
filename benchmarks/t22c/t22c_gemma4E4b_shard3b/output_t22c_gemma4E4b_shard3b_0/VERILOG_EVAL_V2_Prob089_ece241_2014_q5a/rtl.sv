module TopModule (
    input logic clk,
    input logic areset,
    input logic x,
    output logic z
);

    // State encoding
    localparam S0 = 2'b00; // Initial/Carry Propagation Phase
    localparam S1 = 2'b01; // Inversion Phase

    // State registers
    logic [1:0] state;
    logic [1:0] state_next;

    // State Register (Synchronous update, Asynchronous Reset)
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= S0;
        else
            state <= state_next;
    end

    // Next State Logic (Combinational)
    always @(*)
    begin
        state_next = state;

        case (state)
            S0:
                if (x == 1'b1)
                    state_next = S1; // First '1' encountered, switch to inversion
                else
                    state_next = S0; // Still propagating carry (input is 0)
            
            S1:
                state_next = S1; // Stay in inversion mode regardless of input
        endcase
    end

    // Output Logic (Moore Machine - depends only on state)
    // Output z is 0 in S0 (initial carry propagation) and x' in S1 (inversion)
    always @(*) begin
        case (state)
            S0:
                z = 1'b0; // Initial state output
            S1:
                z = ~x; // Inversion phase output
            default: 
                z = 1'b0; // Safety case
        endcase
    end

endmodule