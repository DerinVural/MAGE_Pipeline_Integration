module TopModule (
    input  logic clk,
    input  logic L,
    input  logic q_in,
    input  logic r_in,
    output logic Q
);

    // Internal signal for the multiplexer output
    logic mux_out;

    // Combinational logic: 2:1 Multiplexer
    // If L is high, select r_in. Otherwise, select q_in.
    always @(*) begin
        if (L) begin
            mux_out = r_in;
        end else begin
            mux_out = q_in;
        end
    end

    // Sequential logic: Flip-Flop
    // The output of the multiplexer is fed into the D input of the flip-flop.
    always @(posedge clk) begin
        Q <= mux_out;
    end

endmodule