module TopModule(
    input  logic clk,
    input  logic resetn,
    input  logic x,
    input  logic y,
    output logic f,
    output logic g
);

    // State encoding
    localparam STATE_RESET      = 4'd0;
    localparam STATE_F_PULSE    = 4'd1;
    localparam STATE_WAIT_X     = 4'd2;
    localparam STATE_X1         = 4'd3;
    localparam STATE_X10        = 4'd4;
    localparam STATE_G_START    = 4'd5;
    localparam STATE_G_WAIT_2   = 4'd6;
    localparam STATE_G_PERM     = 4'd7;
    localparam STATE_G_OFF      = 4'd8;

    logic [3:0] state;
    logic [3:0] state_next;

    // Sequential logic for state transition
    always @(posedge clk) begin
        if (!resetn) begin
            state <= STATE_RESET;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        state_next = state;
        case (state)
            STATE_RESET:
                state_next = STATE_F_PULSE;

            STATE_F_PULSE:
                state_next = STATE_WAIT_X;

            STATE_WAIT_X:
                if (x == 1'b1) 
                    state_next = STATE_X1;
                else
                    state_next = STATE_WAIT_X;

            STATE_X1:
                if (x == 1'b0) 
                    state_next = STATE_X10;
                else if (x == 1'b1) 
                    state_next = STATE_X1;
                else
                    state_next = STATE_WAIT_X;

            STATE_X10:
                if (x == 1'b1) 
                    state_next = STATE_G_START;
                else if (x == 1'b0) 
                    state_next = STATE_WAIT_X;
                else
                    state_next = STATE_X1;

            STATE_G_START:
                if (y == 1'b1) 
                    state_next = STATE_G_PERM;
                else
                    state_next = STATE_G_WAIT_2;

            STATE_G_WAIT_2:
                if (y == 1'b1) 
                    state_next = STATE_G_PERM;
                else
                    state_next = STATE_G_OFF;

            STATE_G_PERM:
                state_next = STATE_G_PERM;

            STATE_G_OFF:
                state_next = STATE_G_OFF;

            default:
                state_next = STATE_RESET;
        endcase
    end

    // Combinational logic for outputs
    always @(*) begin
        f = 1'b0;
        g = 1'b0;
        case (state) 
            STATE_F_PULSE:  f = 1'b1;
            STATE_G_START, 
            STATE_G_WAIT_2, 
            STATE_G_PERM:   g = 1'b1;
            // Note: In STATE_G_START and STATE_G_WAIT_2, g is 1.
            // In STATE_G_OFF and others, g is 0.
            default:        g = 1'b0;
        endcase
        
        // Explicitly setting g for the logic above to be safe
        if (state == STATE_G_START || state == STATE_G_WAIT_2 || state == STATE_G_PERM) begin
            g = 1'b1;
        end else begin
            g = 1'b0;
        end
        
        if (state == STATE_F_PULSE) begin
            f = 1'b1;
        end else begin
            f = 1'b0;
        end
    end

endmodule