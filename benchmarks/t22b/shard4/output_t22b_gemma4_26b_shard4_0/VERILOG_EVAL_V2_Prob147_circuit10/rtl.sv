module TopModule (
    input  logic clk,
    input  logic a,
    input  logic b,
    output logic q,
    output logic state
);

    logic state_reg;

    // Initialize state to 0
    initial begin
        state_reg = 1'b0;
    end

    // Sequential logic
    always @(posedge clk) begin
        // ns = (a & b) | (state_reg & (a | b))
        if ((a & b) | (state_reg & (a | b)))
            state_reg <= 1'b1;
        else
            state_reg <= 1'b0;
    end

    // Combinational logic
    always @(*) begin
        // q = a ^ b ^ state_reg
        q = a ^ b ^ state_reg;
    end

    // Structural connections
    assign state = state_reg;

endmodule