module TopModule (
    input  logic       clk,
    input  logic       areset,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Asynchronous active-high reset logic
    // The sensitivity list includes both clk and areset to make it asynchronous
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            q <= 8'h00;
        end else begin
            q <= d;
        end
    end

endmodule