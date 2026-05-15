module TopModule (
    input logic x,
    input logic y,
    output logic z
);

    // Internal wires to hold outputs of the four submodules (A1, A2, B1, B2)
    // A1 and A2 implement Module A logic: z_A = (x ^ y) & x
    logic z_a1;
    logic z_a2;
    // B1 and B2 implement Module B logic: z_B = x NOR y (or x XNOR y)
    logic z_b1;
    logic z_b2;

    // --- Implementation of Module A Logic ---
    // Module A: z = (x ^ y) & x
    assign z_a1 = (x ^ y) & x;
    assign z_a2 = (x ^ y) & x;

    // --- Implementation of Module B Logic ---
    // Module B: z = x XNOR y = NOT (x ^ y)
    assign z_b1 = ~(x ^ y);
    assign z_b2 = ~(x ^ y);

    // --- Aggregation Logic ---

    // 1. First pair connected to OR gate:
    // OR_OUT = Output of A1 OR Output of B1
    logic or_out;
    assign or_out = z_a1 | z_b1;

    // 2. Second pair connected to AND gate:
    // AND_OUT = Output of A2 AND Output of B2
    logic and_out;
    assign and_out = z_a2 & z_b2;

    // 3. Final XOR gate:
    // z = OR_OUT XOR AND_OUT
    assign z = or_out ^ and_out;

endmodule