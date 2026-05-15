module TopModule (
    input logic do_sub,
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] out,
    output logic result_is_zero
);

    // Internal wire to hold the result of the operation (A + B or A - B)
    logic [7:0] result;

    // Combinational logic to perform addition or subtraction
    always @* begin
        if (do_sub == 1'b0) begin
            // Addition
            result = a + b;
        end else begin
            // Subtraction (using two's complement for a - b, which is a + (-b))
            // Since we are using standard SystemVerilog arithmetic, a - b is sufficient.
            result = a - b;
        end
    end

    // Assign the final output value
    assign out = result;

    // Combinational logic for the zero flag
    // The result is zero if and only if all 8 bits of the result are zero.
    assign result_is_zero = (result == 8'b0);

endmodule