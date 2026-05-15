module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic       slowena,
    output logic [3:0] q
);

    // Internal register for the counter
    logic [3:0] count_reg;

    // Initialize the register to a known value
    initial begin
        count_reg = 4'b0000;
    end

    // Sequential logic for the decade counter
    always @(posedge clk) begin
        if (reset) begin
            // Synchronous reset to 0
            count_reg <= 4'b0000;
        end else if (slowena) begin
            // Increment if enabled
            if (count_reg >= 4'd9) begin
                count_reg <= 4'b0000;
            end else begin
                count_reg <= count_reg + 1'b1;
            end
        end
        // If slowena is low, count_reg maintains its value implicitly
    end

    // Continuous assignment to output
    assign q = count_reg;

endmodule