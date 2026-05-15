module TopModule (
    input clk,
    input reset,
    input slowena,
    output logic [3:0] q
);

    // Counter register
    logic [3:0] counter;

    // Initialize counter to 0
    initial begin
        counter = 4'h0;
    end

    // Sequential logic for counter
    always @(posedge clk) begin
        if (reset)
            counter <= 4'h0;
        else if (slowena && counter < 4'd9)
            counter <= counter + 1;
        else if (slowena && counter == 4'd9)
            counter <= 4'h0;
    end

    // Assign output
    assign q = counter;

endmodule