module TopModule (
    input  logic       clk,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Initialize register to avoid X in simulation
    initial begin
        q = 8'b0;
    end

    // 8 D-Flip-Flops triggered by positive edge of clock
    always @(posedge clk) begin
        q <= d;
    end

endmodule