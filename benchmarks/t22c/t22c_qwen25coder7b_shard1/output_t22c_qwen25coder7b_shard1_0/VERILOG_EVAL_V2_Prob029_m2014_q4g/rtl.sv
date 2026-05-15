module TopModule (
    input  logic in1,
    input  logic in2,
    input  logic in3,
    output logic out
);

    // XNOR gate implementation
    logic xnor_result;
    always_comb begin
        xnor_result = (in1 == in2);
    end

    // XOR gate implementation
    assign out = xnor_result ^ in3;

endmodule;