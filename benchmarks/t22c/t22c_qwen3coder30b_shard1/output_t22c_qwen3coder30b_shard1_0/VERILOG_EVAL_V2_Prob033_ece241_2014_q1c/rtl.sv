module TopModule (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] s,
    output       overflow
);

    // Perform the addition
    logic [8:0] sum_with_carry;
    assign sum_with_carry = {1'b0, a} + {1'b0, b};
    assign s = sum_with_carry[7:0];
    
    // Detect overflow
    // Overflow in 2's complement addition happens when:
    // 1. Both operands are positive and result is negative
    // 2. Both operands are negative and result is positive
    // This can be checked using the carry into and out of the sign bit
    assign overflow = (a[7] == b[7]) && (a[7] != sum_with_carry[7]);
    
endmodule