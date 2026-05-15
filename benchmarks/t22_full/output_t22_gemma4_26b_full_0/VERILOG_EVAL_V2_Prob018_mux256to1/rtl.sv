module TopModule(
    input  logic [255:0] in,
    input  logic [7:0]   sel,
    output logic         out
);

    // Combinational logic for the 256-to-1 multiplexer
    // The index 'sel' selects the bit from 'in'
    always @(*) begin
        out = in[sel];
    end

endmodule