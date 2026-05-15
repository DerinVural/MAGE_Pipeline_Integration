module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out
);

    // The provided K-map represents the XOR sum of the four inputs.
    // Let's verify: 
    // a=0, b=0, c=0, d=0 -> 0 ^ 0 ^ 0 ^ 0 = 0 (matches)
    // a=0, b=0, c=0, d=1 -> 0 ^ 0 ^ 0 ^ 1 = 1 (matches)
    // a=0, b=0, c=1, d=1 -> 0 ^ 0 ^ 1 ^ 1 = 0 (matches)
    // a=0, b=0, c=1, d=0 -> 0 ^ 0 ^ 1 ^ 0 = 1 (matches)
    // a=0, b=1, c=0, d=0 -> 0 ^ 1 ^ 0 ^ 0 = 1 (matches)
    // a=0, b=1, c=0, d=1 -> 0 ^ 1 ^ 0 ^ 1 = 0 (matches)
    // a=0, b=1, c=1, d=1 -> 0 ^ 1 ^ 1 ^ 1 = 1 (matches)
    // a=0, b=1, c=1, d=0 -> 0 ^ 1 ^ 1 ^ 0 = 0 (matches)
    // ... and so on.

    assign out = a ^ b ^ c ^ d;

endmodule