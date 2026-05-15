module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out_sop,
    output logic out_pos
);

    // Combinational logic for out_sop (Minimum Sum-of-Products)
    // Minterms: 2 (0010), 7 (0111), 15 (1111)
    // Don't-cares: 3 (0011), 8 (1000), 11 (1011), 12 (1100)
    // Group 1: (2, 3) -> ~a & ~b & c
    // Group 2: (3, 7, 11, 15) -> c & d
    // SOP = (~a & ~b & c) | (c & d)
    always @(*) begin
        out_sop = (~a & ~b & c) | (c & d);
    end

    // Combinational logic for out_pos (Minimum Product-of-Sums)
    // Derived from SOP: c & (d | (~a & ~b))
    // Using distributive law: c & (d | ~a) & (d | ~b)
    // POS = c & (~a | d) & (~b | d)
    always @(*) begin
        out_pos = c & (~a | d) & (~b | d);
    end

endmodule