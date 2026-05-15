module TopModule (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] in,
    output logic [31:0] out
);

    // Internal registers
    logic [31:0] prev_in;
    logic [31:0] out_reg;

    // Initialize registers to avoid X in simulation
    initial begin
        prev_in = 32'h0;
        out_reg = 32'h0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            prev_in <= 32'h0;
            out_reg <= 32'h0;
        end else begin
            // Detect falling edge (1 to 0 transition)
            // A bit is captured if it was 1 in the previous cycle and is 0 now
            out_reg <= out_reg | (prev_in & ~in);
            // Store current input for the next cycle's comparison
            prev_in <= in;
        end
    end

    // Combinational output assignment
    assign out = out_reg;

endmodule