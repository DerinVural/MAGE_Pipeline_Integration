module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

    // State Definition (2 states: A, B)
    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    // State register (1 bit needed)
    logic [0:0] state;
    logic [0:0] state_next;

    // Initialize state register to a known value before reset takes effect
    initial begin
        state = STATE_A; // Initialize to A
    end

    // State Register Logic (Sequential)
    always @(posedge clk)
    begin
        if (reset)
            state <= STATE_B; // Reset state is B (active high synchronous reset)
        else
            state <= state_next;
    end

    // Next State Combinational Logic
    always @(*)
    begin
        state_next = state;

        case (state)
            STATE_A:
                if (in == 0) 
                    state_next = STATE_B; // A --in=0--> B
                else 
                    state_next = STATE_A; // A --in=1--> A

            STATE_B:
                if (in == 0) 
                    state_next = STATE_A; // B --in=0--> A
                else 
                    state_next = STATE_B; // B --in=1--> B

            default: state_next = STATE_A;
        endcase
    end

    // Output Logic (Moore Machine: output depends only on current state)
    always @(*)
    begin
        out = 1'b0;
        case (state)
            STATE_A: out = 1'b0; // A (out=0)
            STATE_B: out = 1'b1; // B (out=1)
            default: out = 1'b0;
        endcase
    end

endmodule