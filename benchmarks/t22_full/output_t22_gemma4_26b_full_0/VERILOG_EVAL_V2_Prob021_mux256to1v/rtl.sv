module TopModule(
    input  logic [1023:0] in,
    input  logic [7:0]    sel,
    output logic [3:0]    out
);

    // The multiplexer selects 4 bits based on the 8-bit sel signal.
    // sel=0 -> in[3:0]
    // sel=1 -> in[7:4]
    // We use the indexed part-select operator: [base_bit +: width]
    // base_bit = sel * 4
    // width = 4

    always @(*) begin
        out = in[sel * 4 +: 4];
    end

endmodule