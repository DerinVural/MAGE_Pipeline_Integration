module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // Combinational logic derived from truth table
    // q is 1 if b is 1 or c is 1
    always @(*) begin
        q = b | c;
    end

endmodule