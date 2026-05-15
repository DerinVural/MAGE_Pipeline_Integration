module TopModule (
    input  logic clk,
    input  logic ar,
    input  logic d,
    output logic q
);

    // Sequential logic
    logic q_reg;
    always @(posedge clk) begin
        if (ar)
            q_reg <= 0;
        else
            q_reg <= d;
    end

    // Assign output
    assign q = q_reg;

endmodule