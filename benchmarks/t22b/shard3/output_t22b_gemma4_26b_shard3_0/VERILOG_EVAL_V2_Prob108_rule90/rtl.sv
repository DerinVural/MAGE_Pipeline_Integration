module TopModule (
    input  logic clk,
    input  logic load,
    input  logic [511:0] data,
    output logic [511:0] q
);

    logic [511:0] q_reg;

    // Initialize to zero to avoid X
    initial begin
        q_reg = 512'b0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (load) begin
            q_reg <= data;
        end else begin
            // Rule 90: next_state[i] = q[i-1] ^ q[i+1]
            // With boundary conditions q[-1]=0 and q[512]=0
            // q_reg << 1 shifts bit i-1 to position i
            // q_reg >> 1 shifts bit i+1 to position i
            q_reg <= (q_reg << 1) ^ (q_reg >> 1);
        end
    end

    // Structural connection
    assign q = q_reg;

endmodule