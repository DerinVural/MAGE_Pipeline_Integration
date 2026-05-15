module TopModule(
    input  logic       clk,
    input  logic       reset,
    output logic [2:0] ena,
    output logic [15:0] q
);

    logic [3:0] d0, d1, d2, d3;

    // Sequential logic for the 4 BCD digits
    always @(posedge clk) begin
        if (reset) begin
            d0 <= 4'd0;
            d1 <= 4'd0;
            d2 <= 4'd0;
            d3 <= 4'd0;
        end else begin
            // Ones digit increments every cycle
            if (d0 == 4'd9) begin
                d0 <= 4'd0;
            end else begin
                d0 <= d0 + 4'd1;
            end

            // Tens digit increments if ones digit is 9
            if (d0 == 4'd9) begin
                if (d1 == 4'd9) begin
                    d1 <= 4'd0;
                end else begin
                    d1 <= d1 + 4'd1;
                end
            end

            // Hundreds digit increments if tens and ones are 9
            if (d0 == 4'd9 && d1 == 4'd9) begin
                if (d2 == 4'd9) begin
                    d2 <= 4'd0;
                end else begin
                    d2 <= d2 + 4'd1;
                end
            end

            // Thousands digit increments if hundreds, tens, and ones are 9
            if (d0 == 4'd9 && d1 == 4'd9 && d2 == 4'd9) begin
                if (d3 == 4'd9) begin
                    d3 <= 4'd0;
                end else begin
                    d3 <= d3 + 4'd1;
                end
            end
        end
    end

    // Combinational logic for enable signals (carry out signals)
    // ena[0] signals the increment for the tens digit
    // ena[1] signals the increment for the hundreds digit
    // ena[2] signals the increment for the thousands digit
    always @(*) begin
        ena[0] = (d0 == 4'd9);
        ena[1] = (d0 == 4'd9 && d1 == 4'd9);
        ena[2] = (d0 == 4'd9 && d1 == 4'd9 && d2 == 4'd9);
    end

    // Output concatenation
    assign q = {d3, d2, d1, d0};

endmodule