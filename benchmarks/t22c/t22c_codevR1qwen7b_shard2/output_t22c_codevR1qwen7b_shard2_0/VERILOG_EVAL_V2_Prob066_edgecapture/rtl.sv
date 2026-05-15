module TopModule (
    input logic clk,
    input logic reset,
    input logic in,
    output logic out
);

    // State variables
    logic previous_bit;
    logic out_reg;

    // Initialize registers to known values
    initial begin
        previous_bit = 0;
        out_reg = 0;
    end

    // Sequential block
    always @(posedge clk) begin
        if (reset) begin
            previous_bit <= 0;
            out_reg <= 0;
        end else begin
            previous_bit <= in;
            if (previous_bit && in) begin
                out_reg <= 1;
            end
            // If not two consecutive ones, retain the output once set unless reset
        end
    end

    // Combinational output assignment
    assign out = out_reg;

endmodule