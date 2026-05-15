module TopModule(
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] q
);

    // The module implements a 32-bit Galois LFSR.
    // Taps are at bit positions 32, 22, 2, and 1.
    // In 0-indexed logic (q[31:0]), these correspond to indices 31, 21, 1, and 0.
    // Galois LFSR right shift: q_next[i] = q[i+1] ^ (is_tap(i+1) ? q[0] : 0).

    always @(posedge clk) begin
        if (reset) begin
            q <= 32'h1;
        end else begin
            // Calculate next state
            // We use a temporary variable to avoid using updated values during the shift
            // though in a non-blocking assignment this is handled automatically.
            
            // q[31] is bit 32
            // q[21] is bit 22
            // q[1]  is bit 2
            // q[0]  is bit 1
            
            // q_next[31] = 0 ^ q[0] (because bit 32 is a tap and there is no q[32])
            // q_next[21] = q[22] ^ q[0]
            // q_next[1]  = q[2] ^ q[0]
            // q_next[0]  = q[1] ^ q[0]
            // Other q_next[i] = q[i+1]

            q[31] <= q[0];
            q[30] <= q[31];
            q[29] <= q[30];
            q[28] <= q[29];
            q[27] <= q[28];
            q[26] <= q[27];
            q[25] <= q[26];
            q[24] <= q[25];
            q[23] <= q[24];
            q[22] <= q[23];
            q[21] <= q[22] ^ q[0];
            q[20] <= q[21];
            q[19] <= q[20];
            q[18] <= q[19];
            q[17] <= q[18];
            q[16] <= q[17];
            q[15] <= q[16];
            q[14] <= q[15];
            q[13] <= q[14];
            q[12] <= q[13];
            q[11] <= q[12];
            q[10] <= q[11];
            q[9]  <= q[10];
            q[8]  <= q[9];
            q[7]  <= q[8];
            q[6]  <= q[7];
            q[5]  <= q[6];
            q[4]  <= q[5];
            q[3]  <= q[4];
            q[2]  <= q[3];
            q[1]  <= q[2] ^ q[0];
            q[0]  <= q[1] ^ q[0];
        end
    end

endmodule