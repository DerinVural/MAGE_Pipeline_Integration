module TopModule(input  logic [7:0] a, input  logic [7:0] b, output logic [7:0] s, output logic overflow);

    // Wires to hold the intermediate results using signed types for correct arithmetic
    logic signed [7:0] sum_signed;
    
    // 1. Perform signed addition
    // By casting inputs to signed, the '+' operator performs two's complement addition.
    assign sum_signed = a + b;
    
    // 2. Assign the 8-bit result to the output 's'
    assign s = sum_signed;
    
    // 3. Compute Overflow
    // Overflow occurs if the signs of the inputs are the same, but the sign of the result differs.
    // A[7] is the sign bit of a, B[7] is the sign bit of b, S[7] is the sign bit of the sum.
    // Overflow = (A[7] == B[7]) AND (A[7] != S[7])
    // Since 'a', 'b', and 's' are derived from signed logic, we check their MSBs.
    assign overflow = (a[7] == b[7]) && (a[7] != s[7]);

endmodule