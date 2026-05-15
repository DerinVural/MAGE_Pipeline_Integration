module TopModule (
    input clk,
    input a,
    output logic [2:0] q
);

    always @(posedge clk) begin
        if (!a)
            q <= 3'd0;
        else
            q <= q + 1;
    end

endmodule