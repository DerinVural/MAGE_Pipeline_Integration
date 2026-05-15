module TopModule (input clk, input reset, output logic [3:0] q);

    // Combinational logic not needed as it's a counter, direct assignment in sequential block
    always_ff @(posedge clk) begin
        if (reset)
            q <= 4'b0;
        else
            q <= q + 1;
    end

    // Initialization of q to avoid X
    initial begin
        q = 4'b0;
    end

endmodule