module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic w,
    output logic z
);

    // State encoding
    localparam STATE_A = 3'd0;
    localparam STATE_B = 3'd1;
    localparam STATE_C = 3'd2;
    localparam STATE_D = 3'd3;
    localparam STATE_E = 3'd4;
    localparam STATE_F = 3'd5;

    logic [2:0] current_state;
    logic [2:0] next_state;

    // Sequential logic: State transition
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state) 
            STATE_A: begin
                if (w == 1'b0) next_state = STATE_B;
                else           next_state = STATE_A;
            end
            STATE_B: begin
                if (w == 1'b0) next_state = STATE_C;
                else           next_state = STATE_D;
            end
            STATE_C: begin
                if (w == 1'b0) next_state = STATE_E;
                else           next_state = STATE_D;
            end
            STATE_D: begin
                if (w == 1'b0) next_state = STATE_F;
                else           next_state = STATE_A;
            end
            STATE_E: begin
                if (w == 1'b0) next_state = STATE_E;
                else           next_state = STATE_D;
            end
            STATE_F: begin
                if (w == 1'b0) next_state = STATE_C;
                else           next_state = STATE_D;
            end
            default: next_state = STATE_A;
        endcase
    end

    // Combinational logic: Output logic (z based on the (0)/(1) in spec)
    always @(*) begin
        case (current_state) 
            STATE_A: z = 1'b0;
            STATE_B: z = 1'b0;
            STATE_C: z = 1'b0;
            STATE_D: z = 1'b0;
            STATE_E: z = 1'b1;
            STATE_F: z = 1'b1;
            default: z = 1'b0;
        endcase
    end

endmodule