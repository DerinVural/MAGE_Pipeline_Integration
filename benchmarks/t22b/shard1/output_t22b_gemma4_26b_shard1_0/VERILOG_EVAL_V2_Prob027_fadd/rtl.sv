module TopModule (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic cout,
    output logic sum
);

    // Combinational logic for Full Adder
    // sum = a XOR b XOR cin
    assign sum = a ^ b ^ cin;

    // cout = (a AND b) OR (cin AND (a XOR b))
    assign cout = (a & b) | (cin & (a ^ b));

endmodule