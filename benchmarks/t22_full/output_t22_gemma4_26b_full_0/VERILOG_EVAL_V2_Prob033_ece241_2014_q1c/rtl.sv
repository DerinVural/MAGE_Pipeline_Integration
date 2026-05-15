module TopModule(
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] s,
    output logic       overflow
);

    // Combinational logic for addition
    always @(*) begin
        s = a + b;
    end

    // Combinational logic for signed overflow detection
    // Overflow occurs if: 
    // (a > 0 && b > 0 && s < 0) OR (a < 0 && b < 0 && s >= 0)
    // In terms of MSB (sign bit):
    // (a[7]==0 && b[7]==0 && s[7]==1) OR (a[7]==1 && b[7]==1 && s[7]==0)
    always @(*) begin
        if ((a[7] == 1'b0 && b[7] == 1'b0 && s[7] == 1'b1) ||
            (a[7] == 1'b1 && b[7] == 1'b1 && s[7] == 1'b0)) begin
            overflow = 1'b1;
        end else begin
            overflow = 1'b0;
        end
    end

endmodule