module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic in,
    output logic out
);

    // State Encoding (2 bits required for 4 states: A, B, C, D)
    localparam [1:0] STATE_A = 2'b00;
    localparam [1:0] STATE_B = 2'b01;
    localparam [1:0] STATE_C = 2'b10;
    localparam [1:0] STATE_D = 2'b11;

    // State register
    logic [1:0] current_state;
    logic [1:0] next_state;

    // State Register Logic (Asynchronous Reset)
    always @(posedge clk or posedge areset) begin
        if (areset)
            current_state <= STATE_A; // Reset to State A
        else
            current_state <= next_state;
    end

    // Next State and Output Logic (Combinational)
    always @(*)
    begin
        // Default assignments to prevent unintended latch inference
        next_state = current_state;
        out = 1'b0; // Default output (Moore FSM)

        case (current_state)
            STATE_A:
            begin
                if (in == 0) 
                    next_state = STATE_A;
                else 
                    next_state = STATE_B;
                out = 1'b0;
            end
            
            STATE_B:
            begin
                if (in == 0) 
                    next_state = STATE_C;
                else 
                    next_state = STATE_B;
                out = 1'b0;
            end
            
            STATE_C:
            begin
                if (in == 0) 
                    next_state = STATE_A;
                else 
                    next_state = STATE_D;
                out = 1'b0;
            end
            
            STATE_D:
            begin
                if (in == 0) 
                    next_state = STATE_C;
                else 
                    next_state = STATE_B;
                out = 1'b1; // Output is 1 only in State D
            end

            default: begin
                next_state = STATE_A; // Should not happen
                out = 1'b0;
            end
        endcase
    end

    // Initialization: Ensure state is not X before the first clock cycle/reset sequence
    initial begin
        current_state = STATE_A;
    end

endmodule