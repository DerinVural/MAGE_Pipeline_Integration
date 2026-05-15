module TopModule (
    input  logic c,
    input  logic d,
    output logic [3:0] mux_in
);

    // Based on the K-map analysis:
    // ab=00 (mux_in[0]): cd=00->0, 01->1, 11->1, 10->1 => c | d
    // ab=01 (mux_in[1]): cd=00->0, 01->0, 11->0, 10->0 => 0
    // ab=11 (mux_in[2]): cd=00->0, 01->0, 11->1, 10->0 => c & d
    // ab=10 (mux_in[3]): cd=00->1, 01->0, 11->1, 10->1 => c | ~d

    always @(*) begin
        mux_in[0] = c | d;
        mux_in[1] = 1'b0;
        mux_in[2] = c & d;
        mux_in[3] = c | (~d);
    end

endmodule