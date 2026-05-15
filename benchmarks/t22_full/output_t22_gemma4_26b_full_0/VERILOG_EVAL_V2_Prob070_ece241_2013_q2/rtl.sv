module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out_sop,
    output logic out_pos
);

    // out_sop in minimum sum-of-products (SOP) form
    // Minterms: 2 (0010), 7 (0111), 15 (1111)
    // Don't-cares: 3 (0011), 8 (1000), 11 (1011), 12 (1100)
    // Group 1: {2, 3} -> ~a & ~b & c
    // Group 2: {3, 7, 11, 15} -> c & d
    assign out_sop = (~a & ~b & c) | (c & d);

    // out_pos in minimum product-of-sums (POS) form
    // Maxterms (0s): 0, 1, 4, 5, 6, 9, 10, 13, 14
    // Don't-cares: 3, 8, 11, 12
    // Grouping 0s:
    // Group 1: {0, 1, 4, 5} -> ~a & ~c (Maxterm: a | c)
    // Group 2: {1, 5, 9, 13} -> ~c & d (Maxterm: c | ~d)
    // Group 3: {4, 6, 12(DC), 14} -> b & ~d (Maxterm: ~b | d)
    // Group 4: {8(DC), 10, 12(DC), 14} -> a & ~d (Maxterm: ~a | d)
    assign out_pos = (a | c) & (c | ~d) & (~b | d) & (~a | d);

endmodule