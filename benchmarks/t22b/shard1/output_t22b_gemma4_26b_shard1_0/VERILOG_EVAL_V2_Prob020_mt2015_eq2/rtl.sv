module TopModule (
    input  logic [1:0] A,
    input  logic [1:0] B,
    output logic       z
);

    // Combinational logic to check if A is equal to B
    always @(*) begin
        if (A == B) begin
            z = 1'b1;
        end else begin
            z = 1'b0;
        end
    end

endmodule