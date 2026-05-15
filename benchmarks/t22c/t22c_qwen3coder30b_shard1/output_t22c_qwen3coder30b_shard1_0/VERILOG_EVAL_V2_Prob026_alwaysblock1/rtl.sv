module TopModule(
    input logic a,
    input logic b,
    output logic out_assign,
    output logic out_alwaysblock
);

    // Using assign statement for AND gate
    assign out_assign = a & b;

    // Using always block for AND gate
    always @(*) begin
        out_alwaysblock = a & b;
    end

endmodule