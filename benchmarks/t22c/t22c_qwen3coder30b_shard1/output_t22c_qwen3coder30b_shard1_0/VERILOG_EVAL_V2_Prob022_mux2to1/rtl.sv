module TopModule(
    input  logic a,
    input  logic b,
    input  logic sel,
    output logic out
);

    always @(*) begin
        if (sel)
            out = b;
        else
            out = a;
    end

endmodule