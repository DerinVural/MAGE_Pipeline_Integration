module TopModule(
    input  logic [254:0] in,
    output logic [7:0] out
);

    // Implementation of 255-bit Population Count using a parallel prefix sum (tree reduction).
    // Max count is 255, requiring 8 bits for the result.

    // --- Stage 1: Sum adjacent pairs (2-bit sums) ---
    // N_in = 255. N_out = ceil(255/2) = 128.
    // Max sum is 2 (0b10), requiring 2 bits.
    logic [1:0] sum_1 [128:0];
    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin
            // Handle boundary case for odd number of bits (index 254)
            logic bit_a = (2*i < 255) ? in[2*i] : 1'b0;
            logic bit_b = (2*i + 1 < 255) ? in[2*i + 1] : 1'b0;

            // Addition: sum_1[i] = bit_a + bit_b
            assign sum_1[i] = bit_a + bit_b;
        end
    endgenerate

    // --- Stage 2: Sum adjacent 2-bit sums (4-bit sums) ---
    // N_in = 128. N_out = 64.
    // Max sum is 4 (0b100), requiring 3 bits.
    logic [2:0] sum_2 [64:0];
    generate
        for (i = 0; i < 64; i = i + 1) begin
            // Sum two 2-bit numbers: sum_1[2*i] + sum_1[2*i + 1]
            assign sum_2[i] = sum_1[2*i] + sum_1[2*i + 1];
        end
    endgenerate

    // --- Stage 3: Sum adjacent 3-bit sums (8-bit sums) ---
    // N_in = 64. N_out = 32.
    // Max sum is 8 (0b1000), requiring 4 bits.
    logic [3:0] sum_3 [32:0];
    generate
        for (i = 0; i < 32; i = i + 1) begin
            // Sum two 3-bit numbers: sum_2[2*i] + sum_2[2*i + 1]
            assign sum_3[i] = sum_2[2*i] + sum_2[2*i + 1];
        end
    endgenerate

    // --- Stage 4: Sum adjacent 4-bit sums (16-bit sums) ---
    // N_in = 32. N_out = 16.
    // Max sum is 16 (0b10000), requiring 5 bits.
    logic [4:0] sum_4 [16:0];
    generate
        for (i = 0; i < 16; i = i + 1) begin
            // Sum two 4-bit numbers: sum_3[2*i] + sum_3[2*i + 1]
            assign sum_4[i] = sum_3[2*i] + sum_3[2*i + 1];
        end
    endgenerate

    // --- Stage 5: Sum adjacent 5-bit sums (32-bit sums) ---
    // N_in = 16. N_out = 8.
    // Max sum is 32 (0b100000), requiring 6 bits.
    logic [5:0] sum_5 [8:0];
    generate
        for (i = 0; i < 8; i = i + 1) begin
            // Sum two 5-bit numbers: sum_4[2*i] + sum_4[2*i + 1]
            assign sum_5[i] = sum_4[2*i] + sum_4[2*i + 1];
        end
    endgenerate

    // --- Stage 6: Sum adjacent 6-bit sums (64-bit sums) ---
    // N_in = 8. N_out = 4.
    // Max sum is 64 (0b1000000), requiring 7 bits.
    logic [6:0] sum_6 [4:0];
    generate
        for (i = 0; i < 4; i = i + 1) begin
            // Sum two 6-bit numbers: sum_5[2*i] + sum_5[2*i + 1]
            assign sum_6[i] = sum_5[2*i] + sum_5[2*i + 1];
        end
    endgenerate

    // --- Stage 7: Sum adjacent 7-bit sums (128-bit sums) ---
    // N_in = 4. N_out = 2 (with remainder handling).
    // Max sum is 128 (0b10000000), requiring 8 bits.
    logic [7:0] sum_7 [2:0];
    generate
        for (i = 0; i < 3; i = i + 1) begin
            // Sum two 7-bit numbers: sum_6[2*i] + sum_6[2*i + 1]
            assign sum_7[i] = sum_6[2*i] + sum_6[2*i + 1];
        end
    endgenerate

    // --- Stage 8: Final Summation ---
    // The final result aggregates all elements from the last fully reduced stage (sum_6) 
    // to correctly cover the 255-bit input.
    logic [7:0] final_count;
    
    // Single driver assignment for final_count
    assign final_count = sum_6[0] + sum_6[1] + sum_6[2] + sum_6[3];

    // Assign the calculated count to the output port.
    assign out = final_count;

endmodule