module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic load,
    input  logic ena,
    input  logic [3:0] data,
    output logic [3:0] q
);

    // Sequential logic for the 4-bit shift register
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Asynchronous reset: reset register to zero
            q <= 4'b0000;
        end else begin
            // Synchronous operations
            if (load) begin
                // Load has higher priority
                q <= data;
            end else if (ena) begin
                // Right shift: q[3] becomes 0, q[0] is shifted out
                // New q[3:0] = {0, q[3], q[2], q[1]}
                q <= {1'b0, q[3:1]};
            end
            // If neither load nor ena is asserted, q remains unchanged
        end
    end

endmodule