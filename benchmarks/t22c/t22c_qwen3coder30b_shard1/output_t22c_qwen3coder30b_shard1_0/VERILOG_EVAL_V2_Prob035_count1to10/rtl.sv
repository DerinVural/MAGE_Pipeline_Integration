module TopModule (
    input clk,
    input reset,
    output logic [3:0] q
);

    // Sequential logic to update the counter
    always @(posedge clk) begin
        if (reset)
            q <= 4'd1;
        else if (q == 4'd10)
            q <= 4'd1;
        else
            q <= q + 1;
    end

endmodule