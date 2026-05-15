module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    input  logic e,
    output logic [24:0] out
);

    // Group the 5 inputs into a 5-bit array for easier indexing.
    // inputs_arr[0] = a, inputs_arr[1] = b, ..., inputs_arr[4] = e
    logic [4:0] inputs_arr = {a, b, c, d, e};

    // Use generate blocks to compute all 25 pairwise comparisons (i vs j)
    genvar i, j;
    generate
        for (i = 0; i < 5; i = i + 1)
        begin
            for (j = 0; j < 5; j = j + 1)
            begin
                // The requirement is: output is 1 if the two bits being compared are equal.
                // Equality (XNOR) is equivalent to NOT (X XOR Y).
                // The index mapping is sequential: out[0] is (a vs a), out[1] is (a vs b), ..., out[24] is (e vs e).
                // The index calculation i*5 + j correctly maps the (i, j) pair to the 1D index.
                assign out[i*5 + j] = ~(inputs_arr[i] ^ inputs_arr[j]);
            end
        end
    endgenerate

endmodule