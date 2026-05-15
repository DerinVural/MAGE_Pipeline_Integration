module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Internal register to hold the state (the output of the DFFs)
    logic [7:0] q_reg;

    // Initialize the register to a known value (e.g., 0) before any clock edge arrives
    initial begin
        q_reg = 8'h00;
    end

    // Sequential logic block for the 8 D flip-flops
    always @(posedge clk)
    begin
        if (reset) begin
            // Synchronous reset: set output to zero
            q_reg <= 8'h00;
        end else begin
            // Normal operation: load data input d
            q_reg <= d;
        end
    end

    // Assign the internal register value to the output port
    assign q = q_reg;

endmodule