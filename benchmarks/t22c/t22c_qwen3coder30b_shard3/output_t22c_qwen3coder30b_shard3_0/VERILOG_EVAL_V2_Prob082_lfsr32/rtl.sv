module TopModule (
    input clk,
    input reset,
    output logic [31:0] q
);

    always @(posedge clk) begin
        if (reset)
            q <= 32'h1;
        else
            q <= {q[30:0] ^ {q[31] ^ q[21] ^ q[1] ^ q[0]}, q[0]};
    end

endmodule