module TopModule(
    input  logic clk,
    input  logic d,
    output logic q
);

    // D Flip-Flop logic
    // The output q captures the value of d on the rising edge of clk.
    always @(posedge clk) begin
        q <= d;
    end

endmodule