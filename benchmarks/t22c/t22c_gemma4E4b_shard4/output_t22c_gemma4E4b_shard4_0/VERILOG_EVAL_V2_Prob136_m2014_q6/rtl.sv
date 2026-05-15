module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic w,
    output logic z
);

    // State Encoding (6 states require 3 bits)
    typedef enum logic [2:0] {
        STATE_A = 3'b000,
        STATE_B = 3'b001,
        STATE_C = 3'b010,
        STATE_D = 3'b011,
        STATE_E = 3'b100,
        STATE_F = 3'b101
    } state_t;

    // State Registers and Next State Logic
    state_t state_current;
    state_t state_next;

    // Initialize state to A on reset or simulation start
    initial begin
        state_current = STATE_A;
    end

    // 1. State Register (Sequential Logic)
    always @(posedge clk)
    begin
        if (reset) begin
            state_current <= STATE_A; // Synchronous Reset to State A
        end else begin
            state_current <= state_next;
        end
    end

    // 2. Next State Logic (Combinational Logic)
    always @(*)
    begin
        state_next = state_current;
        case (state_current) 
            STATE_A:
                if (w == 0) state_next = STATE_B; // A --0--> B
                else state_next = STATE_A;        // A --1--> A
            
            STATE_B:
                if (w == 0) state_next = STATE_C; // B --0--> C
                else state_next = STATE_D;        // B --1--> D
            
            STATE_C:
                if (w == 0) state_next = STATE_E; // C --0--> E
                else state_next = STATE_D;        // C --1--> D
            
            STATE_D:
                if (w == 0) state_next = STATE_F; // D --0--> F
                else state_next = STATE_A;        // D --1--> A
            
            STATE_E:
                if (w == 0) state_next = STATE_E; // E --0--> E
                else state_next = STATE_D;        // E --1--> D
            
            STATE_F:
                if (w == 0) state_next = STATE_C; // F --0--> C
                else state_next = STATE_D;        // F --1--> D
            
            default: state_next = STATE_A; // Safety default
        endcase
    end

    // 3. Output Logic (Combinational Logic)
    // Assuming Z=1 when in State D, and Z=0 otherwise, as output definition was missing from the transitions.
    always @(*)
    begin
        z = 1'b0;
        case (state_current)
            STATE_D: z = 1'b1;
            default: z = 1'b0;
        endcase
    end

endmodule