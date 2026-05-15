module TopModule(
    input  logic [99:0] a,
    input  logic [99:0] b,
    input  logic        sel,
    output logic [99:0] out
);

    // Combinational logic for the 2-1 multiplexer
    always @(*) begin
        if (sel) begin
            out = b;
        end else begin
            out = a;
        end
    end

endmodule