module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Sequential logic
    logic [7:0] q_reg;
    always @(posedge clk) begin
        if (reset)
            q_reg <= 0;
        else
            q_reg <= d;
    end

    // Combinational logic
    always @(*) begin
        q = q_reg;
    end

endmodule