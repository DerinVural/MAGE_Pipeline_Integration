module TopModule (
    input  logic clk,
    input  logic reset,
    output logic [3:1] ena,
    output logic [15:0] q
);

    // Internal registers for each BCD digit
    logic [3:0] ones;
    logic [3:0] tens;
    logic [3:0] hundreds;
    logic [3:0] thousands;

    // Sequential logic for BCD counter
    always @(posedge clk) begin
        if (reset) begin
            ones     <= 4'b0000;
            tens     <= 4'b0000;
            hundreds <= 4'b0000;
            thousands <= 4'b0000;
        end else begin
            // Ones digit always increments
            if (ones == 4'd9) begin
                ones <= 4'd0;
            end else begin
                ones <= ones + 4'd1;
            end

            // Tens digit increments when ones rolls over
            if (ones == 4'd9) begin
                if (tens == 4'd9) begin
                    tens <= 4'd0;
                end else begin
                    tens <= tens + 4'd1;
                end
            end

            // Hundreds digit increments when tens rolls over
            if (ones == 4'd9 && tens == 4'd9) begin
                if (hundreds == 4'd9) begin
                    hundreds <= 4'd0;
                end else begin
                    hundreds <= hundreds + 4'd1;
                end
            end

            // Thousands digit increments when hundreds rolls over
            if (ones == 4'd9 && tens == 4'd9 && hundreds == 4'd9) begin
                if (thousands == 4'd9) begin
                    thousands <= 4'd0;
                end else begin
                    thousands <= thousands + 4'd1;
                end
            end
        end
    end

    // Combinational logic for enable signals
    // ena[1] is for tens, ena[2] for hundreds, ena[3] for thousands
    // According to standard BCD logic, an enable for a digit 
    // is high when its lower digits are at their maximum (9).
    always @(*) begin
        ena[1] = (ones == 4'd9);
        ena[2] = (ones == 4'd9 && tens == 4'd9);
        ena[3] = (ones == 4'd9 && tens == 4'd9 && hundreds == 4'd9);
    end

    // Output assignments
    assign q = {thousands, hundreds, tens, ones};

endmodule