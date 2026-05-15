module TopModule(
    input  logic       clk,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Internal register to act as 8 D flip-flops
    logic [7:0] q_reg;

    // Sequential logic: 8 DFFs triggered by positive edge of clock
    always @(posedge clk) begin
        q_reg <= d;
    end

    // Combinational logic: connect internal register to output
    assign q = q_reg;

endmodule