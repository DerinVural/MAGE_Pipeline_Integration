module TopModule (
    input  logic [2:0] y,
    input  logic w,
    output logic Y1
);

    // Declare the clock signal as a module-level variable
    logic clk;

    // Initialize the clock signal in an initial block
    initial begin
        clk = 0;
        forever #(5) clk = ~clk;
    end

    // Define the state codes
    localparam STATE_A = 3'b000;
    localparam STATE_B = 3'b001;
    localparam STATE_C = 3'b010;
    localparam STATE_D = 3'b011;
    localparam STATE_E = 3'b100;
    localparam STATE_F = 3'b101;

    // Register to store the current state
    logic [2:0] current_state;

    // Sequential logic to update the state on the rising edge of the clock
    always @(posedge clk or posedge w) begin
        if (w)
            current_state <= STATE_A;
        else begin
            case (current_state)
                STATE_A: current_state <= (y[0]) ? STATE_A : STATE_B;
                STATE_B: current_state <= (y[0]) ? STATE_D : STATE_C;
                STATE_C: current_state <= (y[0]) ? STATE_D : STATE_E;
                STATE_D: current_state <= (y[0]) ? STATE_A : STATE_F;
                STATE_E: current_state <= (y[1]) ? STATE_D : STATE_E;
                STATE_F: current_state <= (y[1]) ? STATE_C : STATE_D;
                default: current_state <= STATE_A;
            endcase
        end
    end

    // Combinational logic to determine the output Y1
    always @(*) begin
        Y1 = current_state[1];
    end

endmodule