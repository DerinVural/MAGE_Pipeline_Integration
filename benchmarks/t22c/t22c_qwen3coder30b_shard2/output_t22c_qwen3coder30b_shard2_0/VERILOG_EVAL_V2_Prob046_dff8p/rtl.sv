module TopModule (
    input logic clk,
    input logic reset,
    input logic [7:0] d,
    output logic [7:0] q
);

    // Sequential logic for 8 D flip-flops
    always @(negedge clk) begin
        if (reset)
            q <= 8'h34;  // Reset to 0x34
        else
            q <= d;      // Normal operation
    end

endmodule