module TopModule(
    input  logic clk,
    input  logic L,
    input  logic q_in,
    input  logic r_in,
    output logic Q
);

    logic mux_out;

    // Combinational logic for the 2:1 multiplexer
    always @(*) begin
        if (L) begin
            mux_out = r_in;
        end else begin
            mux_out = q_in;
        end
    end

    // Sequential logic for the flip-flop
    always @(posedge clk) begin
        Q <= mux_out;
    end

endmodule