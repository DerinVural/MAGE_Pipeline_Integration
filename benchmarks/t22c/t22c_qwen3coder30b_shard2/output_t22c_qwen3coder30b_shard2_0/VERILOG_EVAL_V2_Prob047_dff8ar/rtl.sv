module TopModule (
    input logic clk,
    input logic areset,
    input logic [7:0] d,
    output logic [7:0] q
);

    // Initialize q to 0 to avoid X propagation
    initial begin
        q <= 8'b0;
    end

    // Sequential logic for 8 D flip-flops with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset)
            q <= 8'b0;
        else
            q <= d;
    end

endmodule