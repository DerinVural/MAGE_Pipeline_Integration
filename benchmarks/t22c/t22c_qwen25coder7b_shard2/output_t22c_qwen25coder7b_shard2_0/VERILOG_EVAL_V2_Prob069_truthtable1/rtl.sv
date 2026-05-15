module TopModule(
    input logic x3,
    input logic x2,
    input logic x1,
    output logic f
);

    always @(*) begin
        if (x1)
            f = 1;
        else
            f = x2;
    end

endmodule