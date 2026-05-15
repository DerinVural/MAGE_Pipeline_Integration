module TopModule(
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic cout,
    output logic sum
);

    // Full adder logic
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));

endmodule