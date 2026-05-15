module TopModule (
    logic clk,
    logic reset,
    logic w,
    logic z
);

    // Define state parameters
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;
    localparam STATE_E = 2'b100;
    localparam STATE_F = 2'b101;

    // Register to hold the current state
    logic [2:0] state;

    // Initialize the state to STATE_A
    initial begin
        state = STATE_A;
    end

    // Always block for state transition
    always @(posedge clk) begin
        if (reset)
            state <= STATE_A;
        else begin
            case (state)
                STATE_A: state <= (w) ? STATE_B : STATE_A;
                STATE_B: state <= (w) ? STATE_C : STATE_D;
                STATE_C: state <= (w) ? STATE_E : STATE_D;
                STATE_D: state <= (w) ? STATE_F : STATE_A;
                STATE_E: state <= (w) ? STATE_E : STATE_D;
                STATE_F: state <= (w) ? STATE_C : STATE_D;
                default: state <= STATE_A;
            endcase
        end
    end

    // Always block for output assignment
    always @(*) begin
        case (state)
            STATE_A: z = 1'b0;
            STATE_B: z = 1'b0;
            STATE_C: z = 1'b0;
            STATE_D: z = 1'b0;
            STATE_E: z = (w) ? 1'b1 : 1'b0;
            STATE_F: z = (w) ? 1'b0 : 1'b0;
            default: z = 1'b0;
        endcase
    end

endmodule