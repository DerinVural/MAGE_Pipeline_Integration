module TopModule( 
    input clk,
    input reset,
    output logic [9:0] q
);

    // Internal register to hold the counter state
    logic [9:0] count_reg;

    // Initialize the counter to 0 before simulation starts (Requirement #3)
    initial begin
        count_reg = 10'd0;
    end

    // Sequential logic for the counter
    always @(posedge clk)
    begin
        if (reset)
        begin
            // Synchronous reset to 0
            count_reg <= 10'd0;
        end
        else begin
            // Counter logic: Count from 0 to 999.
            // If current count is 999, next count is 0 (wraps around).
            if (count_reg == 10'd999)
            begin
                count_reg <= 10'd0;
            end
            else
            begin
                // Increment the counter
                count_reg <= count_reg + 1;
            end
        end
    end

    // Assign the internal register to the output port
    assign q = count_reg;

endmodule