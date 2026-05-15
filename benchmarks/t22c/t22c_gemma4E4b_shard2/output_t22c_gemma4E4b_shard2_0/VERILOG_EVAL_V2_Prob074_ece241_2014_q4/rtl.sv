module TopModule (
    input logic clk,
    input logic x,
    output logic z
);

    // State Registers (Outputs of the three DFFs)
    logic q0, q1, q2;

    // Internal wires for derived signals (Complements)
    logic q0_n, q1_n, q2_n;

    // Combinational logic for D inputs (D_next)
    // D0 = x XOR Q0
    logic d0_next;
    // D1 = x AND (NOT Q1)
    logic d1_next;
    // D2 = x OR (NOT Q2)
    logic d2_next;

    // --- 1. Initial State Setup (Reset to Zero) ---
    initial begin
        q0 = 1'b0;
        q1 = 1'b0;
        q2 = 1'b0;
    end

    // --- 2. Clocked Logic (D Flip-Flops) ---
    always @(posedge clk)
    begin
        // DFF 0: Q0 <= (x XOR Q0)
        q0 <= d0_next;
        
        // DFF 1: Q1 <= (x AND NOT Q1)
        q1 <= d1_next;
        
        // DFF 2: Q2 <= (x OR NOT Q2)
        q2 <= d2_next;
    end

    // --- 3. Combinational Logic Calculation ---
    always @* begin
        // Calculate complements
        q0_n = ~q0;
        q1_n = ~q1;
        q2_n = ~q2;

        // Calculate D inputs based on the description
        // D0 = x XOR Q0
        d0_next = x ^ q0;
        
        // D1 = x AND (NOT Q1)
        d1_next = x & q1_n;
        
        // D2 = x OR (NOT Q2)
        d2_next = x | q2_n;
    end

    // --- 4. Output Logic (Three-input NOR gate) ---
    // Z = NOR(Q0, Q1, Q2)
    // NOR(A, B, C) = NOT (A OR B OR C)
    assign z = ~(q0 | q1 | q2);

endmodule