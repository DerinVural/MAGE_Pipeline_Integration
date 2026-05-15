module TopModule(
    input  logic       clk,
    input  logic       reset,
    output logic [9:0] q
);

    // Internal counter register
    logic [9:0] counter;

    // Sequential logic for the counter
    always @(posedge clk) begin
        if (reset) begin
            counter <= 10'd0;
        end else begin
            if (counter >= 10'd999) begin
                counter <= 10'd0;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

    // Assign output
    assign q = counter;

endmodule