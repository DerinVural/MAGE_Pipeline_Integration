module TopModule (
    input logic clk,
    input logic reset,
    input logic w,
    output logic z
);

    // State definitions
    localparam STATE_A = 0,
               STATE_B = 1,
               STATE_C = 2,
               STATE_D = 3,
               STATE_E = 4,
               STATE_F = 5;

    logic [2:0] state, next_state;

    // Sequential logic for state transitions
    always @(posedge clk) begin
        if (reset)
            state <= STATE_A;
        else
            state <= next_state;
    end

    // Combinational logic for next_state
    always @(*) begin
        case (state)
            STATE_A: next_state = w ? STATE_A : STATE_B;
            STATE_B: next_state = w ? STATE_D : STATE_C;
            STATE_C: next_state = w ? STATE_D : STATE_E;
            STATE_D: next_state = w ? STATE_A : STATE_F;
            STATE_E: next_state = w ? STATE_D : STATE_E;
            STATE_F: next_state = w ? STATE_D : STATE_C;
            default: next_state = STATE_A;
        endcase
    end

    // Output logic for z
    always @(*) begin
        z = (state == STATE_D || state == STATE_C || state == STATE_E);
    end

endmodule

module tb();
    logic clk = 0;
    logic reset;
    logic w;
    logic z;
    // Instantiate design under test
    TopModule dut (
        .clk(clk),
        .reset(reset),
        .w(w),
        .z(z)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        reset = 1;
        w = 0;
        #10 reset = 0;
        // Add stimulus here according to the state transitions
        // Example: after reset, change w at certain times
        #10 w = 1;
        #10 w = 0;
        // ... Continue as needed
        #100 $finish;
    end

endmodule