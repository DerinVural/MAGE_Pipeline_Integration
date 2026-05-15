module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic w,
    output logic z
);

    // State encoding
    localparam logic [2:0] STATE_A = 3'd0;
    localparam logic [2:0] STATE_B = 3'd1;
    localparam logic [2:0] STATE_C = 3'd2;
    localparam logic [2:0] STATE_D = 3'd3;
    localparam logic [2:0] STATE_E = 3'd4;
    localparam logic [2:0] STATE_F = 3'd5;

    // State registers
    logic [2:0] current_state;
    logic [2:0] next_state;

    // Sequential logic: State Flip-Flops
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next State and Output
    always @(*) begin
        // Default values to prevent latches
        next_state = current_state;
        z = 1'b0;

        case (current_state) 
            STATE_A: begin
                if (w) begin
                    z = 1'b0;
                    next_state = STATE_B;
                end else begin
                    z = 1'b0;
                    next_state = STATE_A;
                end
            end
            STATE_B: begin
                if (w) begin
                    z = 1'b0;
                    next_state = STATE_C;
                end else begin
                    z = 1'b0;
                    next_state = STATE_D;
                end
            end
            STATE_C: begin
                if (w) begin
                    z = 1'b0;
                    next_state = STATE_E;
                end else begin
                    z = 1'b0;
                    next_state = STATE_D;
                end
            end
            STATE_D: begin
                if (w) begin
                    z = 1'b0;
                    next_state = STATE_F;
                end else begin
                    z = 1'b0;
                    next_state = STATE_A;
                end
            end
            STATE_E: begin
                if (w) begin
                    z = 1'b1;
                    next_state = STATE_E;
                end else begin
                    z = 1'b1;
                    next_state = STATE_D;
                end
            end
            STATE_F: begin
                if (w) begin
                    z = 1'b1;
                    next_state = STATE_C;
                end else begin
                    z = 1'b1;
                    next_state = STATE_D;
                end
            end
            default: begin
                next_state = STATE_A;
                z = 1'b0;
            end
        endcase
    end

endmodule