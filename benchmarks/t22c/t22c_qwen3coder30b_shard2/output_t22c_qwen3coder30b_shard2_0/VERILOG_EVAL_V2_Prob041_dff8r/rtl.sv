module TopModule (
    input logic clk,
    input logic reset,
    input logic [7:0] d,
    output logic [7:0] q
);

    logic [7:0] q_reg;

    // Initialize q_reg to zero
    initial begin
        q_reg = 8'b0;
    end

    // Sequential logic for 8 D flip-flops
    always @(posedge clk) begin
        if (reset)
            q_reg <= 8'b0;
        else
            q_reg <= d;
    end

    // Structural connection
    assign q = q_reg;

endmodule