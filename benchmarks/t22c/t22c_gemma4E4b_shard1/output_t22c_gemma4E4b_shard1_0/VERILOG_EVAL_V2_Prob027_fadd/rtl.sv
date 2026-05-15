module TopModule (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic cout,
    output logic sum
);

    // Full Adder Logic:
    // Sum = A XOR B XOR Cin
    assign sum = a ^ b ^ cin;

    // Cout = (A AND B) OR (Cin AND (A XOR B))
    // Using the expanded form for robustness:
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule