module TopModule (
    input  logic clk,
    input  logic w,
    input  logic R,
    input  logic E,
    input  logic L,
    output logic Q
);

    // Registers to hold the shifted values
    logic Q_reg;

    // Sequential logic
    always @(posedge clk) begin
        if (R)
            Q_reg <= R;
        else if (E && !L)
            Q_reg <= w;
        else if (L)
            Q_reg <= w;
    end

    // Combinational logic to drive the output
    assign Q = Q_reg;

endmodule