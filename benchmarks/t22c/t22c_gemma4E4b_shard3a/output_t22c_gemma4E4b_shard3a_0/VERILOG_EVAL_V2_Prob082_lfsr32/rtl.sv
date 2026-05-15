module TopModule (
    input  logic clk,
    input  logic reset,
    output logic [31:0] q
);

    // Internal register for the LFSR state
    logic [31:0] q_reg;

    // Tap definitions: Taps at indices 31 (for 32), 22, 2, 1.
    localparam TAPS_MASK = 32'b1 << 31 | 32'b1 << 22 | 32'b1 << 2 | 32'b1 << 1;

    // Initialize q_reg to 0 before the first clock cycle begins (Non-reset initialization)
    initial begin
        q_reg = 32'b0;
    end

    // Sequential logic for LFSR update
    always @(posedge clk)
    begin
        if (reset)
        begin
            // Synchronous reset to 32'h1 (all ones)
            q_reg <= 32'hFFFFFFFF;
        end
        else
        begin
            // Variables required for the next state calculation
            logic [31:0] q_next;
            logic [32:0] q_shifted_in;
            
            // Initialize variables within the else block scope to satisfy procedural initialization checks
            q_next = 32'b0;
            q_shifted_in = 33'b0;
            
            // Set up the shifted input values (q[i+1])
            // q_shifted_in[0] corresponds to q[32] (assumed 0)
            q_shifted_in[0] = 1'b0;
            // q_shifted_in[32] corresponds to q[32] (assumed 0)
            q_shifted_in[32] = 1'b0;
            // Shift q_reg[30:0] into q_shifted_in[31:1]
            q_shifted_in[31:1] = q_reg[30:0];

            // Calculate the next state bits using the defined Galois LFSR rule:
            // q'[i] = q[i+1] XOR (TapMask[i] AND q[0])
            for (int i = 0; i < 32; i++) begin
                // q[i+1] is found at q_shifted_in[i+1]
                logic shift_in = q_shifted_in[i+1];
                // Check if tap is set AND LSB (q_reg[0]) is 1
                logic feedback_xor = (TAPS_MASK[i] && q_reg[0]) ? 1'b1 : 1'b0;
                
                q_next[i] = shift_in ^ feedback_xor;
            end

            q_reg <= q_next;
        end
    end

    // Assign the internal register to the output port
    assign q = q_reg;

endmodule
