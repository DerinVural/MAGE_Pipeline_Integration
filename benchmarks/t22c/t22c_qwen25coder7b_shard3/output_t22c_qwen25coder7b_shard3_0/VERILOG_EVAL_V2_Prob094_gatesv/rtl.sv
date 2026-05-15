module TopModule (
    input logic [3:0] in,
    output logic [3:0] out_both,
    output logic [3:0] out_any,
    output logic [3:0] out_different
);

// Combinational logic for out_both
always @(*) begin
    out_both = (in[3] & in[0]) << 3 |
               (in[2] & in[3]) << 2 |
               (in[1] & in[2]) << 1 |
               (in[0] & in[1]);
end

// Combinational logic for out_any
always @(*) begin
    out_any = (in[0] | in[1]) << 3 |
              (in[1] | in[2]) << 2 |
              (in[2] | in[3]) << 1 |
              (in[3] | in[0]);
end

// Combinational logic for out_different
always @(*) begin
    out_different = ((in[0] ^ in[1]) << 3) |
                    ((in[1] ^ in[2]) << 2) |
                    ((in[2] ^ in[3]) << 1) |
                    ((in[3] ^ in[0]));
end

endmodule;