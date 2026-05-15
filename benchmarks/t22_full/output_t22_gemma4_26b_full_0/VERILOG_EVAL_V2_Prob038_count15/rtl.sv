module TopModule(
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] q
);

    // Sequential logic for the 4-bit counter
    always @(posedge clk) begin
        if (reset) begin
            // Synchronous active-high reset
            q <= 4'b0000;
        end else begin
            // Increment the counter
            q <= q + 1'b1;
        end
    end

endmodule