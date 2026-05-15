module TopModule(
    input  logic [99:0] in,
    output logic [99:0] out_both,
    output logic [99:0] out_any,
    output logic [99:0] out_different
);

    always @(*) begin
        // Initialize all outputs to 0 to handle boundary conditions easily
        out_both = '0;
        out_any = '0;
        out_different = '0;

        // Calculate out_both
        // out_both[i] is 1 if in[i] and in[i+1] are both 1 (i < 99)
        for (int i = 0; i < 99; i++) begin
            out_both[i] = in[i] & in[i+1];
        end
        out_both[99] = 1'b0;

        // Calculate out_any
        // out_any[i] is 1 if in[i] or in[i-1] are both 1 (i > 0)
        for (int i = 1; i < 100; i++) begin
            out_any[i] = in[i] | in[i-1];
        end
        out_any[0] = 1'b0;

        // Calculate out_different
        // out_different[i] is 1 if in[i] != in[i+1] (with wrap-around for 99)
        for (int i = 0; i < 99; i++) begin
            out_different[i] = in[i] ^ in[i+1];
        end
        out_different[99] = in[99] ^ in[0];
    end

endmodule