module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

    // State encoding
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State registers
    logic [1:0] current_state;
    logic [1:0] next_state;

    // Sequential logic for state transition
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = current_state; // Default
        case (current_state) 
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
        if (current_state == STATE_D) begin
            out = 1'b1;
        end else begin
            out = 1'b0;
        end
    end

endmodule