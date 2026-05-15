module TopModule (
    input c,
    input d,
    output logic [3:0] mux_in
);

    // Directly assign the values according to Karnaugh map
    // cd = 00 -> ab = 00 -> mux_in[0] = 0
    // cd = 01 -> ab = 01 -> mux_in[1] = 1
    // cd = 11 -> ab = 11 -> mux_in[2] = 1
    // cd = 10 -> ab = 10 -> mux_in[3] = 1
    
    always @(*) begin
        mux_in[0] = 1'b0;
        mux_in[1] = c;
        mux_in[2] = c | d;
        mux_in[3] = c & ~d;
    end

endmodule