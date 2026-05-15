module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

    // State encoding using localparam
    localparam logic [1:0] STATE_A = 2'b00;
    localparam logic [1:0] STATE_B = 2'b01;
    localparam logic [1:0] STATE_C = 2'b10;
    localparam logic [1:0] STATE_D = 2'b11;

    // State registers
    logic [1:0] current_state;
    logic [1:0] next_state;

    // Initialize state to avoid X in simulation
    initial begin
        current_state = STATE_A;
    end

    // Sequential logic: State transition with synchronous reset
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state = current_state; // Default assignment to avoid latches
        case (current_state)
            STATE_A: begin
                if (in == 1'b1) next_state = STATE_B;
                else            next_state = STATE_A;
            end
            STATE_B: begin
                if (in == 1'b1) next_state = STATE_B;
                else            next_state = STATE_C;
            end
            STATE_C: begin
                if (in == 1'b1) next_state = STATE_D;
                else            next_state = STATE_A;
            end
            STATE_D: begin
                if (in == 1'b1) next_state = STATE_B;
                else            next_state = STATE_C;
            end
            default: next_state = STATE_A;
        endcase
    end

    // Combinational logic: Moore Output logic
    always @(*) begin
        if (current_state == STATE_D) begin
            out = 1'b1;
        end else begin
            out = 1'b0;
        end
    end

endmodule