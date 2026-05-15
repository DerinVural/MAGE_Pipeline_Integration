module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic clk,
    output logic w,
    output logic x,
    output logic y,
    output logic z
);

    // Internal signals
    logic w_reg;
    logic x_reg;
    logic y_reg;
    logic z_reg;

    // Initialization block
    initial begin
        w_reg = 0;
        x_reg = 0;
        y_reg = 0;
        z_reg = 0;
    end

    // Assignments
    assign w = w_reg;
    assign x = x_reg;
    assign y = y_reg;
    assign z = z_reg;

    // Sequential logic
    always_ff @(posedge clk) begin
        w_reg <= a;
        x_reg <= b;
        y_reg <= b;
        z_reg <= c;
    end

endmodule