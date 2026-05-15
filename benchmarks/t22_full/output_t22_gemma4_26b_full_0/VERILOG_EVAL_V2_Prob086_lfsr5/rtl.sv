module TopModule(
    input  logic clk,
    input  logic reset,
    output logic [4:0] q
);

    // Internal register to hold the state
    logic [4:0] q_reg;

    // Combinational logic for the next state
    // Based on the Galois LFSR description:
    // A bit position with a tap is XORed with the LSB output bit (q[0]) to produce its next value.
    // Other bits shift right (q[i] becomes q[i+1]).
    // Taps are at positions 5 and 3, which correspond to indices 4 and 2.
    logic [4:0] q_next;

    always @(*) begin
        // Default: right shift
        q_next[4] = 1'b0;
        q_next[3] = q_reg[4];
        q_next[2] = q_reg[3];
        q_next[1] = q_reg[2];
        q_next[0] = q_reg[1];

        // Apply tap XORs
        // Tap at position 5 (index 4)
        q_next[4] = q_next[4] ^ q_reg[0];
        // Tap at position 3 (index 2)
        q_next[2] = q_next[2] ^ q_reg[0];
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            // Reset to 1 as specified
            q_reg <= 5'b00001;
        end else begin
            q_reg <= q_next;
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule