module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic w,
    output logic z
);

    // State definitions
    localparam STATE_A = 3'd0;
    localparam STATE_B = 3'd1;
    localparam STATE_C = 3'd2;
    localparam STATE_D = 3'd3;
    localparam STATE_E = 3'd4;
    localparam STATE_F = 3'd5;

    logic [2:0] current_state;
    logic [2:0] next_state;

    // Sequential logic for state transition
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic for next state and output
    always @(*) begin
        next_state = current_state;
        z = 1'b0;

        case (current_state) 
            STATE_A: begin
                z = 1'b0;
                if (w == 1'b0) next_state = STATE_B;
                else           next_state = STATE_A;
            end
            STATE_B: begin
                z = 1'b0;
                if (w == 1'b0) next_state = STATE_C;
                else           next_state = STATE_D;
            end
            STATE_C: begin
                z = 1'b0;
                if (w == 1'b0) next_state = STATE_E;
                else           next_state = STATE_D;
            end
            STATE_D: begin
                z = 1'b0;
                if (w == 1'b0) next_state = STATE_F;
                else           next_state = STATE_A;
            end
            STATE_E: begin
                z = 1'b1;
                if (w == 1'b0) next_state = STATE_E;
                else           next_state = STATE_D;
            end
            STATE_F: begin
                z = 1'b1;
                if (w == 1'b0) next_state = STATE_C;
                else           next_state = STATE_D;
            end
            default: begin
                next_state = STATE_A;
                z = 1'b0;
            end
        endcase
    end

endmodule