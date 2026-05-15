module TopModule(
    input  logic c,
    input  logic d,
    output logic [3:0] mux_in
);

    // Combinational logic for the 4 inputs of the 4-to-1 MUX
    // mux_in[0] is for ab=00: c | d
    // mux_in[1] is for ab=01: 0
    // mux_in[2] is for ab=10: c | ~d
    // mux_in[3] is for ab=11: c & d

    always @(*) begin
        // mux_in[0] = c | d implemented via 2-to-1 MUX: c ? 1 : d
        mux_in[0] = c ? 1'b1 : d;

        // mux_in[1] = 0
        mux_in[1] = 1'b0;

        // mux_in[2] = c | ~d implemented via 2-to-1 MUXes: c ? 1 : (~d)
        // Since ~d is not a MUX, we use a 2-to-1 MUX to implement NOT d: d ? 0 : 1
        mux_in[2] = c ? 1'b1 : (d ? 1'b0 : 1'b1);

        // mux_in[3] = c & d implemented via 2-to-1 MUX: c ? d : 0
        mux_in[3] = c ? d : 1'b0;
    end

endmodule