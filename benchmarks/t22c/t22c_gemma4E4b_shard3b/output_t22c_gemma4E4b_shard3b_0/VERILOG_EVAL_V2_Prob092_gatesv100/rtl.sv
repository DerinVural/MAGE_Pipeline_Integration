module TopModule (
    input  logic [99:0] in,
    output logic [99:0] out_both,
    output logic [99:0] out_any,
    output logic [99:0] out_different
);

    // 1. out_both: out_both[i] = in[i] & in[i+1]. out_both[99] = 0.
    // out_both[i] = in[i] & in[i+1] for i=0 to 98
    assign out_both[98:0] = in[98:0] & in[99:1];
    assign out_both[99] = 1'b0;

    // 2. out_any: out_any[i] = in[i] | in[i-1]. out_any[0] = 0.
    // out_any[i] = in[i] | in[i-1] for i=1 to 99
    assign out_any[99:1] = in[99:1] | in[98:0];
    assign out_any[0] = 1'b0;

    // 3. out_different: out_different[i] = in[i] ^ in[i+1] (wrapped).
    // Using always_comb for procedural generation of indexed assignment.
    always_comb begin
        for (int i = 0; i < 100; i++) begin
            // Neighbor to the left is at index (i + 1) % 100
            int neighbor_index = (i + 1) % 100;
            out_different[i] = in[i] ^ in[neighbor_index];
        end
    end

endmodule