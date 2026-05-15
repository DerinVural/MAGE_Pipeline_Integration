module TopModule (
    input clk,
    input [7:0] d,
    output logic [7:0] q
);

    // 8 D flip-flops, each triggered on the positive edge of clk
    always @(posedge clk) begin
        q <= d;
    end

endmodule