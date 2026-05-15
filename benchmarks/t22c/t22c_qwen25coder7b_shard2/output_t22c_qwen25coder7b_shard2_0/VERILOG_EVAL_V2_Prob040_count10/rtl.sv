module TopModule (
    input  logic clk,
    input  logic reset,
    output logic [3:0] q
);

    logic [3:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            count <= 4'd0;
        else
            count <= (reset) ? 4'd0 : (count == 4'd9) ? 4'd0 : count + 1;
    end

    assign q = count;

endmodule