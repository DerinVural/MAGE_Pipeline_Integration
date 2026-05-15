module TopModule(clk, reset, ena, q);
    input logic clk;
    input logic reset;
    output logic [2:0] ena;
    output logic [15:0] q;

    // 4-digit BCD counters: thousands, hundreds, tens, ones
    logic [3:0] thousands;
    logic [3:0] hundreds;
    logic [3:0] tens;
    logic [3:0] ones;

    // Ena signals: ena[0] is always 1 when ones increment, ena[1] when tens increment, etc.
    // ena[2:0] correspond to thousands, hundreds, tens

    // Initialize all registers to 0 except maybe ones to start at 1? Wait, BCD counter starts at 0.

    // Initialize all digits to 0 with initial block
    initial begin
        thousands = 4'd0;
        hundreds = 4'd0;
        tens = 4'd0;
        ones = 4'd0;
        ena = 3'b111; // default enables all digits to increment when lower digits reach max
    end

    // Combinational logic for ena signals
    always @(*) begin
        ena[0] = (ones == 4'd9); // enable tens when ones overflows
        ena[1] = (tens == 4'd9) & ena[0]; // enable hundreds when tens overflows and ena[0] is active
        ena[2] = (hundreds == 4'd9) & ena[1]; // enable thousands when hundreds overflows and ena[1] is active
    end

    // Sequential logic for counters
    always @(posedge clk) begin
        if (reset) begin
            // Reset to 0 or initial state
            thousands <= 4'd0;
            hundreds <= 4'd0;
            tens <= 4'd0;
            ones <= 4'd0;
        end else begin
            // Increment ones every cycle if not reset
            if (ones < 4'd9) begin
                ones <= ones + 4'd1;
            end else begin
                ones <= 4'd0;
            end

            // Handle carry over to tens if enabled
            if (ena[0]) begin
                if (tens < 4'd9) begin
                    tens <= tens + 4'd1;
                end else begin
                    tens <= 4'd0;
                end
            end

            // Handle hundreds if enabled
            if (ena[1]) begin
                if (hundreds < 4'd9) begin
                    hundreds <= hundreds + 4'd1;
                end else begin
                    hundreds <= 4'd0;
                end
            end

            // Handle thousands if enabled
            if (ena[2]) begin
                if (thousands < 4'd9) begin
                    thousands <= thousands + 4'd1;
                end else begin
                    thousands <= 4'd0;
                end
            end
        end
    end

    // Combine all digits into q output
    assign q = {thousands, hundreds, tens, ones};

endmodule
