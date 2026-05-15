module TopModule (
    input clk,
    input reset,
    output logic [3:0] q
);

    always @(posedge clk) begin
        if (reset)
            q <= 4'd0;
        else
            q <= q + 1;
    end

endmodule