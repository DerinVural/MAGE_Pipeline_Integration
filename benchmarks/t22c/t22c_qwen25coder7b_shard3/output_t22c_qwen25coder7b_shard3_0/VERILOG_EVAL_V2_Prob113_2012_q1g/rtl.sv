module TopModule(
    input  logic [3:0] x,
    output logic f
);

    // Combinational logic
    logic count;
    assign count = (x[3] & 1'b1) + (x[2] & 1'b1) + (x[1] & 1'b1);

    // Output logic
    assign f = (count == 1'b1);

endmodule