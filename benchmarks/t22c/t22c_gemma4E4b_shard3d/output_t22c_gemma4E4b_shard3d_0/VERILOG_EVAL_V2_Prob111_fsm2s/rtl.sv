module TopModule (
    input logic clk,
    input logic reset,
    input logic j,
    input logic k,
    output logic out
);

    // State definition: 1 bit (0 = OFF, 1 = ON)
    logic [0:0] state_current;
    logic [0:0] state_next;

    // Initialize state_current to OFF (0) at simulation start
    initial begin
        state_current = 1'b0; // Initial state is OFF
    end

    // 1. State Register (Sequential Logic)
    always @(posedge clk)
    begin
        if (reset)
            state_current <= 1'b0; // Synchronous reset to OFF
        else
            state_current <= state_next;
    end

    // 2. Next State Logic (Combinational Logic)
    always @(*)
    begin
        state_next = state_current;

        case (state_current)
            1'b0: begin // Current State = OFF
                if (j) 
                    state_next = 1'b1; // OFF --j=1--> ON
                else 
                    state_next = 1'b0; // OFF --j=0--> OFF
            end

            1'b1: begin // Current State = ON
                if (k) 
                    state_next = 1'b0; // ON --k=1--> OFF
                else 
                    state_next = 1'b1; // ON --k=0--> ON
            end

            default: state_next = 1'b0;
        endcase
    end

    // 3. Output Logic (Moore Machine: Output = State)
    // OFF (state=0) -> out=0; ON (state=1) -> out=1
    assign out = state_current;

endmodule