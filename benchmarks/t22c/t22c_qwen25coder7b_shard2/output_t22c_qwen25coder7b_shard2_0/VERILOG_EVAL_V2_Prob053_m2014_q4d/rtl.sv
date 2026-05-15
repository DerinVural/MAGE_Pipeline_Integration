module TopModule (
    input wire clk,
    input wire in,
    output wire out
);

    // Sequential logic for D flip-flop
    logic d_flip_flop;
    always @(posedge clk) begin
        d_flip_flop <= in ^ out;
    end

    // Assigning the output of the flip-flop
    assign out = d_flip_flop;

endmodule