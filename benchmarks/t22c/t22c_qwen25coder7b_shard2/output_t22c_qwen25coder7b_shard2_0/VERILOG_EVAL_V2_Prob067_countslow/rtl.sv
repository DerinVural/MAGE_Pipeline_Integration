module TopModule (
    logic clk,
    logic reset,
    logic slowena,
    logic [3:0] q
);

    logic [3:0] count;

    initial begin
        count = 0;
    end

    always @(posedge clk) begin
        if (reset)
            count <= 0;
        else if (slowena)
            count <= (count == 9) ? 0 : count + 1;
    end

    assign q = count;

endmodule