module TopModule (
    input  logic clk,
    input  logic resetn,
    input  logic [1:0] byteena,
    input  logic [15:0] d,
    output logic [15:0] q
);

    // Register to hold the output data (16 D flip-flops)
    logic [15:0] q_reg = 16'h0;

    // Synchronous logic block
    always @(posedge clk)
    begin
        if (!resetn) begin
            // Active-low synchronous reset to zero
            q_reg <= 16'h0000;
        end else begin
            // Default behavior: hold the current value
            q_reg <= q_reg;

            // Update upper byte if enabled
            if (byteena[1]) begin
                q_reg[15:8] <= d[15:8];
            end

            // Update lower byte if enabled
            if (byteena[0]) begin
                q_reg[7:0] <= d[7:0];
            end
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule