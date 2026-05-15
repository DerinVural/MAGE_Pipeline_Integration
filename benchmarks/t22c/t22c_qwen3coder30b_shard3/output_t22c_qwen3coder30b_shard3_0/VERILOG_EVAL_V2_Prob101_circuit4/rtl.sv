module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    always @(*) begin
        q = c | (a & b);
    end

endmodule