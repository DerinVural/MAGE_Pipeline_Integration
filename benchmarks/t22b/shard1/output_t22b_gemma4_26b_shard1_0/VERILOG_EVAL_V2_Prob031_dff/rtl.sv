module TopModule (
    input  logic clk,
    input  logic d,
    output logic q
);

    // Initialize output to a known value to avoid X in simulation
    initial begin
        q = 1'b0;
    end

    // Sequential logic for D Flip-Flop
    always @(posedge clk) begin
        q <= d;
    end

endmodule