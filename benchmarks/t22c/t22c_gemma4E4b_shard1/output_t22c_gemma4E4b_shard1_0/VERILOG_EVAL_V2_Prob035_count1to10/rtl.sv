module TopModule(
    input  logic clk,
    input  logic reset,
    output logic [3:0] q
);

    // Internal register to hold the counter value
    logic [3:0] counter_reg;

    // Initialize the register to a known value (e.g., 0) before reset is asserted
    initial begin
        counter_reg = 4'b0000;
    end

    // Synchronous Decade Counter Logic (Counts 1 to 10, loops 1 -> 2 -> ... -> 10 -> 1)
    always @(posedge clk)
    begin
        if (reset)
        begin
            // Synchronous reset sets the counter to 1
            counter_reg <= 4'b0001;
        end
        else
        begin
            // Check for the wrap-around condition (10 -> 1)
            if (counter_reg == 4'd10) begin
                counter_reg <= 4'b0001; // Wrap back to 1
            end
            // Normal increment
            else begin
                counter_reg <= counter_reg + 1'b1;
            end
        end
    end

    // Assign the internal register to the output port
    assign q = counter_reg;

endmodule