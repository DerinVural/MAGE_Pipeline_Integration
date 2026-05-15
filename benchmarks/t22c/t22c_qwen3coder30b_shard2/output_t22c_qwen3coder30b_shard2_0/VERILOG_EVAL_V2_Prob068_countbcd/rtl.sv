module TopModule (
    input clk,
    input reset,
    output [2:0] ena,
    output [15:0] q
);

    // Internal signals
    logic [15:0] q_reg;
    logic [3:0] ones_digit;
    logic [3:0] tens_digit;
    logic [3:0] hundreds_digit;
    logic [3:0] thousands_digit;

    // Digit enable signals
    logic ena_ones;
    logic ena_tens;
    logic ena_hundreds;

    // Sequential logic for registering q
    always @(posedge clk) begin
        if (reset)
            q_reg <= 16'h0;
        else
            q_reg <= q_reg;
    end

    // Extract individual digits from q
    assign ones_digit = q_reg[3:0];
    assign tens_digit = q_reg[7:4];
    assign hundreds_digit = q_reg[11:8];
    assign thousands_digit = q_reg[15:12];

    // Enable logic
    assign ena_ones = 1'b1; // Ones digit increments every cycle
    assign ena_tens = (ones_digit == 4'd9); // Tens increments when ones wraps
    assign ena_hundreds = (tens_digit == 4'd9); // Hundreds increments when tens wraps
    assign ena[0] = ena_ones;
    assign ena[1] = ena_tens;
    assign ena[2] = ena_hundreds;

    // Next state calculation
    logic [3:0] ones_next;
    logic [3:0] tens_next;
    logic [3:0] hundreds_next;
    logic [3:0] thousands_next;

    // Combinational logic to calculate next values
    always @(*) begin
        ones_next = ones_digit + 1;
        tens_next = tens_digit;
        hundreds_next = hundreds_digit;
        thousands_next = thousands_digit;

        // Handle ones digit overflow
        if (ones_digit == 4'd9) begin
            ones_next = 4'd0;
            tens_next = tens_digit + 1;
        end

        // Handle tens digit overflow
        if (tens_digit == 4'd9 && ones_digit == 4'd9) begin
            tens_next = 4'd0;
            hundreds_next = hundreds_digit + 1;
        end

        // Handle hundreds digit overflow
        if (hundreds_digit == 4'd9 && tens_digit == 4'd9 && ones_digit == 4'd9) begin
            hundreds_next = 4'd0;
            thousands_next = thousands_digit + 1;
        end
    end

    // Sequential logic for updating the counter
    always @(posedge clk) begin
        if (reset) begin
            q_reg <= 16'h0;
        end else begin
            q_reg[3:0] <= ones_next;
            q_reg[7:4] <= tens_next;
            q_reg[11:8] <= hundreds_next;
            q_reg[15:12] <= thousands_next;
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule