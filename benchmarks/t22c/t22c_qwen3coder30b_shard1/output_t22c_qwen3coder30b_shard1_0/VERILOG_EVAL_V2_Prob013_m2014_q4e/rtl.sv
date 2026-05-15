module TopModule(
    input  logic in1,
    input  logic in2,
    output logic out
);

    // NOR gate implementation: out = !(in1 || in2)
    always @(*) begin
        out = !(in1 || in2);
    end

endmodule