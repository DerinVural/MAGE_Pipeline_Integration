module TopModule ( 
    input logic clk, 
    input logic areset, 
    input logic in, 
    output logic out 
);

    // State encoding
    localparam STATE_A = 2'b00; // Corresponds to A in diagram
    localparam STATE_B = 2'b01; // Corresponds to B in diagram

    // State registers
    logic [1:0] state;
    logic [1:0] state_next;

    // Initialization for registers (Rule 3)
    initial begin
        state = STATE_A; // Initialize to a known state before reset is applied
    end

    // 1. Sequential Logic (State Register) - Asynchronous Reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Asynchronous reset to State B
            state <= STATE_B;
        end else begin
            state <= state_next;
        end
    end

    // 2. Next State Combinational Logic
    always @(*)
    begin
        state_next = state;
        case (state)
            STATE_A: begin
                if (in == 0) 
                    state_next = STATE_B; // A(0) --0--> B
                else 
                    state_next = STATE_A; // A(0) --1--> A
            end
            STATE_B: begin
                if (in == 0) 
                    state_next = STATE_A; // B(1) --0--> A
                else 
                    state_next = STATE_B; // B(1) --1--> B
            end
            default: state_next = STATE_A; // Safety case
        endcase
    end

    // 3. Output Logic (Moore Machine - Output depends only on current state)
    // Assuming: State B outputs 1, State A outputs 0 (a common interpretation when output logic isn't fully specified for a Moore machine)
    always @(*)
    begin
        out = 1'b0; // Default output
        case (state)
            STATE_A: out = 1'b0;
            STATE_B: out = 1'b1; // Set output high in State B
            default: out = 1'b0;
        endcase
    end

endmodule