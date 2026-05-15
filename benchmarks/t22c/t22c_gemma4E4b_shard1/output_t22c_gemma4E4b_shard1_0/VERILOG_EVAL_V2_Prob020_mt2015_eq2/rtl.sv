module TopModule (
    input  logic [1:0] A,
    input  logic [1:0] B,
    output logic z
);

    // z is 1 if A equals B, otherwise z is 0.
    assign z = (A == B);

endmodule