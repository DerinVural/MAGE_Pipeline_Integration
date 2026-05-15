module TopModule (
    input logic [99:0] in,
    output logic [99:0] out_both,
    output logic [99:0] out_any,
    output logic [99:0] out_different
);

    // Initialize outputs to 0
    initial begin
        out_both = 0;
        out_any = 0;
        out_different = 0;
    end

    // Calculate out_both
    always @(*) begin
        out_both[0] = 0; // No left neighbor for the first element
        for (int i = 1; i < 100; i++) begin
            out_both[i] = in[i] & in[i-1];
        end
    end

    // Calculate out_any
    always @(*) begin
        out_any[99] = 0; // No right neighbor for the last element
        for (int i = 0; i < 99; i++) begin
            out_any[i] = in[i] | in[i+1];
        end
    end

    // Calculate out_different
    always @(*) begin
        out_different[0] = in[0] != in[99]; // Wrap around condition
        for (int i = 1; i < 100; i++) begin
            out_different[i] = in[i] != in[i-1];
        end
    end

endmodule