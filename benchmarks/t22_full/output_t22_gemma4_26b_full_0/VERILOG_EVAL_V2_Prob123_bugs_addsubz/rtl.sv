module TopModule (
    input  logic       do_sub,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] out,
    output logic       result_is_zero
);

    always @(*) begin
        // Calculate out based on do_sub
        if (do_sub == 1'b1) begin
            out = a - b;
        end else begin
            out = a + b;
        end

        // Calculate result_is_zero based on the calculated out
        // This must be outside the 'if (~out)' to avoid latching
        if (out == 8'b0) begin
            result_is_zero = 1'b1;
        end else begin
            result_is_zero = 1'b0;
        end
    end

endmodule