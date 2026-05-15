module TopModule(
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] q
);

    // Sequential logic for the decade counter
    always @(posedge clk) begin
        if (reset) begin
            // Reset the counter to 1
            q <= 4'd1;
        end else begin
            if (q >= 4'd10) begin
                // Wrap around to 1 after reaching 10
                q <= 4'd1;
            end else begin
                // Increment the counter
                q <= q + 4'd1;
            end
        end
    end

endmodule