module TopModule (
    input clk,
    input reset,
    output logic [3:0] q
);

    // Sequential logic
    always @(posedge clk) begin
        if (reset)
            q <= 4'd0;
        else if (q == 4'd9)
            q <= 4'd0;
        else
            q <= q + 1'd1;
    end

endmodule