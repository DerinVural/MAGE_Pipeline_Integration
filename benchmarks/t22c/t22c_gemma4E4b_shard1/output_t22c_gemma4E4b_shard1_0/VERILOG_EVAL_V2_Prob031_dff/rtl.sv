module TopModule(
    input  logic clk,
    input  logic d,
    output logic q
);

    // Internal register to hold the state of the flip-flop
    logic q_reg;

    // Initialize the flip-flop output to a known state (0) at simulation start
    initial begin
        q_reg = 1'b0;
    end

    // Sequential logic for the D Flip-Flop
    always @(posedge clk) begin
        // On the positive edge of clk, the output q_reg takes the value of input d
        q_reg <= d;
    end

    // Drive the output port from the internal register
    assign q = q_reg;

endmodule