module TopModule (
    input  logic x3,
    input  logic x2,
    input  logic x1,
    output logic f
);

    // Implementation based on the provided truth table using a continuous assignment.
    // Truth Table Mapping:
    // 000 -> 0, 001 -> 0
    // 010 -> 1, 011 -> 1
    // 100 -> 0, 101 -> 1
    // 110 -> 0, 111 -> 1

    assign f = (x3 == 0 && x2 == 0 && x1 == 0) ? 1'b0 : 
               (x3 == 0 && x2 == 0 && x1 == 1) ? 1'b0 : 
               (x3 == 0 && x2 == 1 && x1 == 0) ? 1'b1 : 
               (x3 == 0 && x2 == 1 && x1 == 1) ? 1'b1 : 
               (x3 == 1 && x2 == 0 && x1 == 0) ? 1'b0 : 
               (x3 == 1 && x2 == 0 && x1 == 1) ? 1'b1 : 
               (x3 == 1 && x2 == 1 && x1 == 0) ? 1'b0 : 
               (x3 == 1 && x2 == 1 && x1 == 1) ? 1'b1 : 1'bx;

endmodule