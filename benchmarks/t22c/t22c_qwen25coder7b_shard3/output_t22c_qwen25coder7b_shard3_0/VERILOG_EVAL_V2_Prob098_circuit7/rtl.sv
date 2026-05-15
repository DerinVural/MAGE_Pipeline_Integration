module TopModule (
    input logic clk,
    input logic a,
    output logic q
);

    // Initialize q to 0
    logic q_reg;
    always_ff @(posedge clk) begin
        if (q_reg == 0 && a == 1)
            q_reg <= 1;
        else if (q_reg == 1 && a == 0)
            q_reg <= 0;
        else
            q_reg <= q_reg;
    end

    assign q = q_reg;

endmodule