module TopModule (
    input clk,
    input L,
    input q_in,
    input r_in,
    output Q
);

    // Internal signals for the 2:1 multiplexer and flip-flop
    logic mux_out;
    logic reg_out;

    // 2:1 Multiplexer implementation
    always @(*) begin
        if (L)
            mux_out = r_in;
        else
            mux_out = q_in;
    end

    // Flip-flop
    always @(posedge clk) begin
        reg_out <= mux_out;
    end

    // Output assignment
    assign Q = reg_out;

endmodule