module TopModule (
    input logic clk,
    input logic d,
    input logic r,
    output logic q
);

    logic q_reg;

    always @(posedge clk) begin
        if (r)
            q_reg <= 0;
        else
            q_reg <= d;
    end

    assign q = q_reg;

endmodule