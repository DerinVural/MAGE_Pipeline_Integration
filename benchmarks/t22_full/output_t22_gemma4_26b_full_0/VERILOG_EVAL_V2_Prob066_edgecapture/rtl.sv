module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic [31:0] in,
    output logic [31:0] out
);

    logic [31:0] prev_in;
    logic [31:0] out_reg;

    // Initialize registers to 0 to avoid X in simulation
    initial begin
        prev_in = 32'h0;
        out_reg = 32'h0;
    end

    // Sequential logic to capture the falling edges and maintain sticky bits
    always @(posedge clk) begin
        if (reset) begin
            out_reg <= 32'h0;
        end else begin
            // A falling edge is when the previous bit was 1 and current bit is 0
            // out_reg is sticky: once a bit is 1, it stays 1 until reset
            out_reg <= out_reg | (prev_in & ~in);
        end
    end

    // Sequential logic to store the previous input state
    always @(posedge clk) begin
        prev_in <= in;
    end

    // Output assignment
    assign out = out_reg;

endmodule