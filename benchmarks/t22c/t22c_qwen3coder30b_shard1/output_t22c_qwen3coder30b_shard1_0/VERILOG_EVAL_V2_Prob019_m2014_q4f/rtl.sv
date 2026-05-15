module TopModule(
    input  logic in1,
    input  logic in2,
    output logic out
);

    // Implement the circuit: AND gate with bubble on in2
    always @(*) begin
        out = in1 & ~in2;
    end

endmodule