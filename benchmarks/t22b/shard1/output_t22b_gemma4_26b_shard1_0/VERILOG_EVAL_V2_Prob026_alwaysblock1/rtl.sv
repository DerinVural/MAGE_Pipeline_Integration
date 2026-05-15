module TopModule (
    input  logic a,
    input  logic b,
    output logic out_assign,
    output logic out_alwaysblock
);

    // Implementation using assign statement
    assign out_assign = a & b;

    // Implementation using combinational always block
    always @(*) begin
        out_alwaysblock = a & b;
    end

endmodule