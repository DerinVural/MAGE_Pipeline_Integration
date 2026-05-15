module TopModule(
    input  logic       clk,
    input  logic       reset,
    output logic [4:0] q
);

    // Sequential logic for the LFSR
    always @(posedge clk) begin
        if (reset) begin
            // Active-high synchronous reset to 1
            q <= 5'b00001;
        end else begin
            // Galois LFSR: shift right
            // q_next[4:0] = {1'b0, q[4:1]}
            // If q[0] is 1, XOR the tap positions with 1
            // Taps are at pos 5 (index 4) and pos 3 (index 2)
            if (q[0]) begin
                q <= ( {1'b0, q[4:1]} ) ^ 5'b10100;
            end else begin
                q <= {1'b0, q[4:1]};
            end
        end
    end

endmodule