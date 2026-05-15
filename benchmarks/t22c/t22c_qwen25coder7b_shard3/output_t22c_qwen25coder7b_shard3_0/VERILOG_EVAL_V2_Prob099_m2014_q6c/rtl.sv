module TopModule (
    input logic [5:0] y,
    input logic w,
    input logic reset,
    output logic Y2,
    output logic Y4
);

    // Define states using localparams for clarity
    localparam STATE_A = 6'b000001;
    localparam STATE_B = 6'b000010;
    localparam STATE_C = 6'b000100;
    localparam STATE_D = 6'b001000;
    localparam STATE_E = 6'b010000;
    localparam STATE_F = 6'b100000;

    // Register to hold the current state
    logic [5:0] state;

    // Initialize state register
    initial begin
        state = STATE_A;
    end

    // Always block to update the state on the rising edge of the clock
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= STATE_A;
        else
            state <= state_next;
    end

    // Next state logic
    logic [5:0] state_next;
    always @(*) begin
        case (state)
            STATE_A:
                state_next = (w) ? STATE_A : STATE_B;
            STATE_B:
                state_next = (w) ? STATE_D : STATE_C;
            STATE_C:
                state_next = (w) ? STATE_D : STATE_E;
            STATE_D:
                state_next = (w) ? STATE_A : STATE_F;
            STATE_E:
                state_next = (w) ? STATE_D : STATE_E;
            STATE_F:
                state_next = (w) ? STATE_C : STATE_D;
            default:
                state_next = STATE_A;
        endcase
    end

    // Output logic for Y2 and Y4
    always @(*) begin
        Y2 = (y == STATE_B || y == STATE_C || y == STATE_D) ? 1'b1 : 1'b0;
        Y4 = (y == STATE_D) ? 1'b1 : 1'b0;
    end

endmodule