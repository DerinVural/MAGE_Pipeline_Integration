module TopModule (
    input  logic clk,
    input  logic ar,
    input  logic d,
    output logic q
);

    // D flip-flop with asynchronous reset
    // The sensitivity list includes 'posedge ar' to make the reset asynchronous
    always @(posedge clk or posedge ar) begin
        if (ar) begin
            q <= 1'b0;
        end else begin
            q <= d;
        end
    end

endmodule