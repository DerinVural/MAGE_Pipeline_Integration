module TopModule (
    input  logic clk,
    input  logic reset,
    output logic [3:0] q
);

    // Internal register to hold the counter value
    logic [3:0] counter_reg;

    // Initialize the counter to 0 before the first clock edge (Constraint 3)
    initial begin
        counter_reg = 4'b0000;
    end

    // Synchronous sequential logic for the counter (Constraint 2)
    always @(posedge clk)
    begin
        if (reset)
        begin
            // Active high synchronous reset to 0
            counter_reg <= 4'b0000;
        end
        else
        begin
            // Decade counter logic (0 to 9, wraps from 9 to 0)
            if (counter_reg == 4'd9)
            begin
                counter_reg <= 4'b0000; // Wrap around
            end
            else
            begin
                // Increment by 1
                counter_reg <= counter_reg + 1'b1;
            end
        end
    end

    // Assign the register value to the output port
    assign q = counter_reg;

endmodule