module TopModule (
    input logic clk,
    input logic [7:0] d,
    output logic [7:0] q
);

    // Internal register to hold the state of the 8 D Flip-Flops
    logic [7:0] q_reg;

    // Initialize the register to a known value (0) at simulation start
    initial begin
        q_reg = 8'b0; // Initialize all 8 bits to zero
    end

    // D Flip-Flop implementation: Positive edge triggered synchronous update
    always @(posedge clk) begin
        // The next state (q_reg) takes the value of the input d
        q_reg <= d;
    end

    // Assign the internal register value to the module output
    assign q = q_reg;

endmodule