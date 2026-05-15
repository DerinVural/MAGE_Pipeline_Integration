module TopModule (
    input logic d,
    input logic ena,
    input logic clk,
    output logic q
);

    logic q_reg;

    always @(posedge clk) begin
        if (ena)
            q_reg <= d;
        else
            q_reg <= q_reg; // Ensure q_reg stays stable when ena is low
    end

    assign q = q_reg;

endmodule