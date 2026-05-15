module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out
);

    // Implementation using casez to handle Don't Care conditions from the K-map.
    // The input combination {a, b, c, d} must map correctly to the K-map indexing.
    // We assume standard binary representation for the input bits.

    always_comb begin
        // Default assignment for all unlisted combinations (although ideally all 16 states are covered by the K-map mapping).
        out = 1'b0; 

        casez ( {a, b, c, d} )
            // cd=00 (Row 1) -> ab=01(d), 00(0), 10(1), 11(1)
            4'b0100: out = 1'bx; // d (ab=01, cd=00)
            4'b0000: out = 1'b0; // 0 (ab=00, cd=00)
            4'b1000: out = 1'b1; // 1 (ab=10, cd=00)
            4'b1100: out = 1'b1; // 1 (ab=11, cd=00)

            // cd=01 (Row 2) -> ab=01(0), 00(0), 10(d), 11(d)
            4'b0101: out = 1'b0; // 0 (ab=01, cd=01)
            4'b0001: out = 1'b0; // 0 (ab=00, cd=01)
            4'b1001: out = 1'bx; // d (ab=10, cd=01)
            4'b1101: out = 1'bx; // d (ab=11, cd=01)

            // cd=11 (Row 3) -> ab=01(0), 00(1), 10(1), 11(1)
            4'b0111: out = 1'b0; // 0 (ab=01, cd=11)
            4'b0011: out = 1'b1; // 1 (ab=00, cd=11)
            4'b1011: out = 1'b1; // 1 (ab=10, cd=11)
            4'b1111: out = 1'b1; // 1 (ab=11, cd=11)

            // cd=10 (Row 4) -> ab=01(0), 00(1), 10(1), 11(1)
            4'b0110: out = 1'b0; // 0 (ab=01, cd=10)
            4'b0010: out = 1'b1; // 1 (ab=00, cd=10)
            4'b1010: out = 1'b1; // 1 (ab=10, cd=10)
            4'b1110: out = 1'b1; // 1 (ab=11, cd=10)

            default: out = 1'b0;
        endcase
    end

endmodule