module TopModule (
    input  logic       do_sub,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] out,
    output logic       result_is_zero
);

    always @(*) begin
        // Default values to prevent latches
        out = 8'b0;
        result_is_zero = 1'b0;

        // Perform addition or subtraction
        if (do_sub) begin
            out = a - b;
        end else begin
            out = a + b;
        end

        // Calculate zero flag based on the result
        if (out == 8'b0) begin
            result_is_zero = 1'b1;
        end else begin
            result_is_zero = 1'b0;
        end
    end

endmodule