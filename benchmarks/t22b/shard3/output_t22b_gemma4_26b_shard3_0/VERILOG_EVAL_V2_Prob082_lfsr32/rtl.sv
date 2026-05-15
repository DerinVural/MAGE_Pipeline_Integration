module TopModule (
    input  logic clk,
    input  logic reset,
    output logic [31:0] q
);

    logic [31:0] q_reg;
    logic [31:0] q_next;

    // Initialize to a known value to avoid X
    initial begin
        q_reg = 32'h1;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            q_reg <= 32'h1;
        end else begin
            q_reg <= q_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        // Default right shift
        q_next = {1'b0, q_reg[31:1]};
        
        // Apply Galois XOR taps
        // Taps at 32, 22, 2, 1 (1-based) -> 31, 21, 1, 0 (0-based)
        // The rule: next_q[i] = q[i+1] ^ q[0] if i is a tap
        // For index 31: next_q[31] = q[32] ^ q[0] -> since q[32] is 0, next_q[31] = q[0]
        
        // Note: The shift already handles next_q[i] = q[i+1] for most bits.
        // We just need to XOR the feedback q[0] into the tap positions.
        
        // Position 32 (index 31)
        q_next[31] = q_reg[0]; // The bit shifted in is q[0]
        
        // Position 22 (index 21)
        q_next[21] = q_reg[22] ^ q_reg[0];
        
        // Position 2 (index 1)
        q_next[1] = q_reg[2] ^ q_reg[0];
        
        // Position 1 (index 0)
        q_next[0] = q_reg[1] ^ q_reg[0];
        
        // For all other bits, they follow the shift
        // We must be careful not to overwrite the taps incorrectly.
        // Let's rewrite the combinational logic more cleanly.
    end

    // Corrected combinational logic to avoid overwriting
    always @(*) begin
        // Step 1: Perform the right shift
        // next_q[31] becomes the feedback bit
        // next_q[30:0] = q_reg[31:1]
        q_next = {1'b0, q_reg[31:1]};
        
        // Step 2: The bit being shifted in (at index 31) is q_reg[0]
        q_next[31] = q_reg[0];

        // Step 3: XOR the feedback bit q_reg[0] into the tap positions
        // Tap 32 (idx 31): next_q[31] = q_reg[0] ^ q_reg[0] = 0? 
        // Wait, the specification says: 'a bit position with a tap is XORed with the LSB output bit (q[0]) to produce its next value'.
        // If tap is at 32 (idx 31), next_q[31] = q[32] ^ q[0]. Since q[32]=0, next_q[31] = q[0].
        // If tap is at 22 (idx 21), next_q[21] = q[22] ^ q[0].
        // If tap is at 2 (idx 1), next_q[1] = q[2] ^ q[0].
        // If tap is at 1 (idx 0), next_q[0] = q[1] ^ q[0].
        
        // Let's use this exact logic.
        // To ensure we don't overwrite, we calculate q_next[31:0] based on the rule.
        
        // Non-tap bits:
        // next_q[30] = q[31]
        // next_q[29] = q[30] ...
        
        // We can use a loop or manual assignment.
        // Manual assignment is safer for small widths.
        
        q_next[31] = q_reg[0]; // Tap 32 (idx 31): q[32] is 0, so 0 ^ q[0] = q[0]
        q_next[30] = q_reg[31];
        q_next[29] = q_reg[30];
        q_next[28] = q_reg[29];
        q_next[27] = q_reg[28];
        q_next[26] = q_reg[27];
        q_next[25] = q_reg[26];
        q_next[24] = q_reg[25];
        q_next[23] = q_reg[24];
        q_next[22] = q_reg[23];
        q_next[21] = q_reg[22] ^ q_reg[0]; // Tap 22 (idx 21)
        q_next[20] = q_reg[21];
        q_next[19] = q_reg[20];
        q_next[18] = q_reg[19];
        q_next[17] = q_reg[18];
        q_next[16] = q_reg[17];
        q_next[15] = q_reg[16];
        q_next[14] = q_reg[15];
        q_next[13] = q_reg[14];
        q_next[12] = q_reg[13];
        q_next[11] = q_reg[12];
        q_next[10] = q_reg[11];
        q_next[9]  = q_reg[10];
        q_next[8]  = q_reg[9];
        q_next[7]  = q_reg[8];
        q_next[6]  = q_reg[7];
        q_next[5]  = q_reg[6];
        q_next[4]  = q_reg[5];
        q_next[3]  = q_reg[4];
        q_next[2]  = q_reg[3];
        q_next[1]  = q_reg[2] ^ q_reg[0]; // Tap 2 (idx 1)
        q_next[0]  = q_reg[1] ^ q_reg[0]; // Tap 1 (idx 0)
    end

    assign q = q_reg;

endmodule