module TopModule (input logic clk, input logic reset, output logic [9:0] q);

    logic [9:0] counter;

    // Initialize counter to 0
    initial counter = 10'b0;

    // Counter logic
    always_ff @(posedge clk) begin
        if (reset)
            counter <= 10'b0;
        else begin
            if (counter == 10'd999)
                counter <= 10'b0;
            else
                counter <= counter + 1;
        end
    end

    // Assign output
    assign q = counter;

endmodule