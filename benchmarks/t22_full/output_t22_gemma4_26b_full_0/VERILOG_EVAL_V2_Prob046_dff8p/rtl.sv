module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Sequential logic: 8 D flip-flops triggered by negative edge of clk
    // with active high synchronous reset to 0x34
    always @(negedge clk) begin
        if (reset) begin
            q <= 8'h34;
        end else begin
            q <= d;
        end
    end

endmodule