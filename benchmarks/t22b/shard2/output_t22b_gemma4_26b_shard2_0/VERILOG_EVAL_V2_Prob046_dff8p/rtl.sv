module TopModule (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // The flip-flops are triggered by the negative edge of clk.
    // The reset is active high and synchronous.
    // The reset value is specified as 0x34.
    always @(negedge clk) begin
        if (reset) begin
            q <= 8'h34;
        end else begin
            q <= d;
        end
    end

endmodule