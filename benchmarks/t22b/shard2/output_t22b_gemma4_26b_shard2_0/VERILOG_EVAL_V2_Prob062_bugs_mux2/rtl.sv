module TopModule (
    input  logic       sel,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] out
);

    // The bug in the original code was likely due to bitwise operations on a single-bit selector
    // being extended incorrectly. Using the ternary operator ensures the entire 8-bit
    // vector is selected based on the single-bit sel.
    assign out = sel ? b : a;

endmodule