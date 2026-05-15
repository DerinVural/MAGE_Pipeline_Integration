module TopModule (
    input clk,
    input reset,
    output [4:0] q
);

    logic [4:0] q_reg;

    always @(posedge clk) begin
        if (reset)
            q_reg <= 5'b00001;
        else begin
            logic new_bit;
            new_bit = q_reg[4] ^ q_reg[2];
            q_reg <= {new_bit, q_reg[4:1]};
        end
    end

    assign q = q_reg;

endmodule