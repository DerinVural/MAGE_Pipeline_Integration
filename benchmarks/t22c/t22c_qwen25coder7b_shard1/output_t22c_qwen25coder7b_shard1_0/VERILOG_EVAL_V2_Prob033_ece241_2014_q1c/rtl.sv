module TopModule (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] s,
    output logic overflow
);

    // Internal wires for full adder
    logic [8:0] sum;
    logic carry;

    // Full adder logic
    always @(*) begin
        sum = a + b;
        carry = sum[8];
    end

    // Assign output
    assign s = sum[7:0];
    assign overflow = carry;

endmodule