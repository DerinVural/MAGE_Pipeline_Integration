module TopModule(clk, reset, q); 
    input wire clk; 
    input wire reset; 
    output logic [31:0] q; 

    // Shift register
    logic [31:0] shift_reg;

    // Tap positions
    localparam TAP_32 = 1 << 31;
    localparam TAP_22 = 1 << 21;
    localparam TAP_2  = 1 << 1;
    localparam TAP_1  = 1 << 0;

    // Register for output q
    logic [31:0] q_reg;

    // Initial state
    initial begin
        q_reg = 32'h1;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset)
            q_reg <= 32'h1;
        else
            q_reg <= shift_reg;
    end

    // Combinational logic
    always @(*) begin
        shift_reg = {shift_reg[30:0], (shift_reg & TAP_32) ^ (shift_reg & TAP_22) ^ (shift_reg & TAP_2) ^ (shift_reg & TAP_1)};
    end

    // Structural connections
    assign q = q_reg;

endmodule