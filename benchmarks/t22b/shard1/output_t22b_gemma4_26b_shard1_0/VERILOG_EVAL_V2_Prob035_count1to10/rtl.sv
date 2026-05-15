module TopModule (
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] q
);

    // Internal register to hold the counter value
    logic [3:0] count_reg;

    // Initialize the register to a known value to avoid X in simulation
    initial begin
        count_reg = 4'd1;
    end

    // Sequential logic for the decade counter
    always @(posedge clk) begin
        if (reset) begin
            // Synchronous reset to 1
            count_reg <= 4'd1;
        end else begin
            if (count_reg >= 4'd10) begin
                // Wrap around from 10 to 1
                count_reg <= 4'd1;
            end else begin
                // Increment the counter
                count_reg <= count_reg + 4'd1;
            end
        end
    end

    // Combinational output assignment
    assign q = count_reg;

endmodule