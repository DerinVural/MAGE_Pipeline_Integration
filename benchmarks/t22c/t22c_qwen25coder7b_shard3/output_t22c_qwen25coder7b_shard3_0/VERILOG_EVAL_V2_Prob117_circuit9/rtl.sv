module TopModule (
    input logic clk,
    input logic a,
    output logic [2:0] q
);

    logic [2:0] count;

    always_ff @(posedge clk) begin
        if (a) begin
            count <= 3'd4;
        end else begin
            if (count == 3'd6)
                count <= 3'd0;
            else
                count <= count + 1;
        end
    end

    assign q = count;

endmodule