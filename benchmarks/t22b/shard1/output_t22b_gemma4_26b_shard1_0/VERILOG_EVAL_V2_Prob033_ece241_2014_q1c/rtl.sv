module TopModule (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] s,
    output logic       overflow
);

    // Combinational logic for addition and overflow detection
    always @(*) begin
        // Perform 8-bit addition
        s = a + b;
        
        // Signed overflow detection:
        // If two numbers have the same sign, but the result has a different sign.
        // a[7] is the sign bit of a
        // b[7] is the sign bit of b
        // s[7] is the sign bit of the result
        if ((a[7] == b[7]) && (s[7] != a[7])) begin
            overflow = 1'b1;
        end else begin
            overflow = 1'b0;
        end
    end

endmodule