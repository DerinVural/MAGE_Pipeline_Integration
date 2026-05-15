module TopModule ( 
    input logic clk,
    input logic reset,
    input logic w,
    output logic z
);

    // State Encoding (3 bits needed for 6 states)
    localparam logic [2:0] STATE_A = 3'b000;
    localparam logic [2:0] STATE_B = 3'b001;
    localparam logic [2:0] STATE_C = 3'b010;
    localparam logic [2:0] STATE_D = 3'b011;
    localparam logic [2:0] STATE_E = 3'b100;
    localparam logic [2:0] STATE_F = 3'b101;

    // State registers and next state wire
    logic [2:0] current_state;
    logic [2:0] next_state;

    // Initialization of state register (Requirement 3)
    initial begin
        current_state = STATE_A;
    end

    // State Flip-Flops (Sequential Logic) - Requirement: Separate always block for state flip-flops
    always @(posedge clk)
    begin
        if (reset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // State Table (Next State Logic) - Requirement: always @(*)
    always @(*)
    begin
        next_state = current_state; // Default assignment

        case (current_state)
            STATE_A:
                if (w == 1'b1) next_state = STATE_B; // A --1--> B
                else next_state = STATE_A; // A --0--> A
            STATE_B:
                if (w == 1'b1) next_state = STATE_C; // B --1--> C
                else next_state = STATE_D; // B --0--> D
            STATE_C:
                if (w == 1'b1) next_state = STATE_E; // C --1--> E
                else next_state = STATE_D; // C --0--> D
            STATE_D:
                if (w == 1'b1) next_state = STATE_F; // D --1--> F
                else next_state = STATE_A; // D --0--> A
            STATE_E:
                if (w == 1'b1) next_state = STATE_E; // E --1--> E
                else next_state = STATE_D; // E --0--> D
            STATE_F:
                if (w == 1'b1) next_state = STATE_C; // F --1--> C
                else next_state = STATE_D; // F --0--> D
            default: next_state = STATE_A; // Safety case
        endcase
    end

    // Output Logic (Combinational Assignment) - Requirement: always @(*)
    // Assuming z=1 when in state E or F, based on common FSM practices when output logic is ambiguous.
    always @(*)
    begin
        z = 1'b0;
        case (current_state)
            STATE_E: z = 1'b1; // E(1) --> E
            STATE_F: z = 1'b1; // F(1) --> C
            default: z = 1'b0;
        endcase
    end

endmodule