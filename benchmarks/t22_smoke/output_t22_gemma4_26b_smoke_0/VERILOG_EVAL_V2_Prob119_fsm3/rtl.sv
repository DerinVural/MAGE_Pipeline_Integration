module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic in,
    output logic out
);

    // State encoding
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State registers
    logic [1:0] state;
    logic [1:0] next_state;

    // Sequential logic for state transitions
    // Asynchronous active-high reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_A;
        end else begin
            state <= next_state;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = state;
        case (state) 
            STATE_A: begin
                if (in == 1'b0) next_state = STATE_A;
                else           next_state = STATE_B;
            end
            STATE_B: begin
                if (in == 1'b0) next_state = STATE_C;
                else           next_state = STATE_B;
            end
            STATE_C: begin
                if (in == 1'b0) next_state = STATE_A;
                else           next_state = STATE_D;
            end
            STATE_D: begin
                if (in == 1'b0) next_state = STATE_C;
                else           next_state = STATE_B;
            end
            default: next_state = STATE_A;
        endcase
    end

    // Combinational logic for output (Moore machine)
    always @(*) begin
        if (state == STATE_D) begin
            out = 1'b1;
        end else begin
            out = 1'b0;
        end
    end

endmodule