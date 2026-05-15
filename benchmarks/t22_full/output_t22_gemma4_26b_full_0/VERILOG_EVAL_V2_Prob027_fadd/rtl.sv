module TopModule(
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic cout,
    output logic sum
);

    // Combinational logic for full adder
    // sum = a XOR b XOR cin
    // cout = (a AND b) OR (b AND cin) OR (a AND cin)
    
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule