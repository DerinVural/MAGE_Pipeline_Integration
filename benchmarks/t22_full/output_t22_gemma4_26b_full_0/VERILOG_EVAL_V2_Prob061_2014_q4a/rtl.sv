module TopModule(
    input  logic clk,
    input  logic w,
    input  logic R,
    input  logic E,
    input  logic L,
    output logic Q
);

    // The module acts as a single stage in a shift register.
    // Priority: 
    // 1. Load (L): if L is high, Q gets the value of R.
    // 2. Shift (E): if L is low and E is high, Q gets the value of w.
    // 3. Hold: otherwise, Q maintains its current value.

    always @(posedge clk) begin
        if (L) begin
            Q <= R;
        end else if (E) begin
            Q <= w;
        end else begin
            Q <= Q;
        end
    end

endmodule