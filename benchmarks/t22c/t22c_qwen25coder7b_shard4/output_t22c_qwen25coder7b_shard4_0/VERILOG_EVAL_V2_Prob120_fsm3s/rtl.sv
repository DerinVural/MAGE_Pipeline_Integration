module TopModule (
    input logic clk,
    input logic reset,
    input logic in,
    output logic out
);

    // Define state parameters
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // Register for current state
    logic [1:0] state;

    // Initial block to set the state to A initially
    initial state = STATE_A;

    // Always block for state transition
    always @(posedge clk) begin
        if (reset)
            state <= STATE_A;
        else begin
            case (state)
                STATE_A: state <= (in) ? STATE_B : STATE_A;
                STATE_B: state <= (in) ? STATE_C : STATE_B;
                STATE_C: state <= (in) ? STATE_A : STATE_D;
                STATE_D: state <= (in) ? STATE_C : STATE_B;
                default: state <= STATE_A;
            endcase
        end
    end

    // Output logic based on the state
    always @(*) begin
        case (state)
            STATE_A: out = 1'b0;
            STATE_B: out = 1'b0;
            STATE_C: out = 1'b0;
            STATE_D: out = 1'b1;
            default: out = 1'b0;
        endcase
    end

endmodule