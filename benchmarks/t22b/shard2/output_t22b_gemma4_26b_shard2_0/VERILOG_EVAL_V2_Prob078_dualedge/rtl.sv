module TopModule (
    input  logic clk,
    input  logic d,
    output logic q
);

    logic q_pos;
    logic q_neg;

    // Initialize to avoid X in simulation
    initial begin
        q_pos = 1'b0;
        q_neg = 1'b0;
    end

    // Capture d on the positive edge
    always @(posedge clk) begin
        q_pos <= d;
    end

    // Capture d on the negative edge
    always @(negedge clk) begin
        q_neg <= d;
    end

    // Combine the two to behave like a dual-edge FF.
    // When clk is high, the most recent edge was either a posedge or a negedge.
    // However, the logic 'clk ? q_pos : q_neg' is a standard way to implement 
    // dual-edge functionality in FPGA-friendly RTL.
    assign q = clk ? q_pos : q_neg;

endmodule