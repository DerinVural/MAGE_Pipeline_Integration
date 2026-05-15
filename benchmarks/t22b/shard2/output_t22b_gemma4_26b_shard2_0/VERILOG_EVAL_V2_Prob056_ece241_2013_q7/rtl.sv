module TopModule (
    input  logic clk,
    input  logic j,
    input  logic k,
    output logic Q
);

    // Initialize Q to a known value to avoid X in simulation
    initial begin
        Q = 1'b0;
    end

    // Sequential logic for the JK flip-flop
    always @(posedge clk) begin
        case ({j, k})
            2'b00: Q <= Q;      // Hold
            2'b01: Q <= 1'b0;   // Reset
            2'b10: Q <= 1'b1;   // Set
            2'b11: Q <= ~Q;    // Toggle
        endcase
    end

endmodule