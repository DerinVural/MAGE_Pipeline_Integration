module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    input  logic done_counting,
    input  logic ack,
    output logic shift_ena,
    output logic counting,
    output logic done
);

    // State definitions
    localparam STATE_IDLE      = 4'd0;
    localparam STATE_S1        = 4'd1;
    localparam STATE_S11       = 4'd2;
    localparam STATE_S110      = 4'd3;
    localparam STATE_SHIFT1    = 4'd4;
    localparam STATE_SHIFT2    = 4'd5;
    localparam STATE_SHIFT3    = 4'd6;
    localparam STATE_SHIFT4    = 4'd7;
    localparam STATE_WAIT_COUNT = 4'd8;
    localparam STATE_WAIT_ACK   = 4'd9;

    logic [3:0] state;
    logic [3:0] next_state;

    // State transition logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state combinational logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_IDLE:
                if (data == 1'b1)      next_state = STATE_S1;
                else                   next_state = STATE_IDLE;
            
            STATE_S1:
                if (data == 1'b1)      next_state = STATE_S11;
                else if (data == 1'b0) next_state = STATE_IDLE;
                else                   next_state = STATE_S1;

            STATE_S11:
                if (data == 1'b1)      next_state = STATE_S11;
                else if (data == 1'b0) next_state = STATE_S110;
                else                   next_state = STATE_S1;

            STATE_S110:
                if (data == 1'b1)      next_state = STATE_SHIFT1;
                else                   next_state = STATE_IDLE;

            STATE_SHIFT1:
                next_state = STATE_SHIFT2;

            STATE_SHIFT2:
                next_state = STATE_SHIFT3;

            STATE_SHIFT3:
                next_state = STATE_SHIFT4;

            STATE_SHIFT4:
                next_state = STATE_WAIT_COUNT;

            STATE_WAIT_COUNT:
                if (done_counting == 1'b1) next_state = STATE_WAIT_ACK;
                else                       next_state = STATE_WAIT_COUNT;

            STATE_WAIT_ACK:
                if (ack == 1'b1)           next_state = STATE_IDLE;
                else                       next_state = STATE_WAIT_ACK;

            default:
                next_state = STATE_IDLE;
        endcase
    end

    // Output combinational logic
    always @(*) begin
        shift_ena = 1'b0;
        counting  = 1'b0;
        done      = 1'b0;

        case (state) 
            STATE_SHIFT1, STATE_SHIFT2, STATE_SHIFT3, STATE_SHIFT4:
                shift_ena = 1'b1;
            STATE_WAIT_COUNT:
                counting  = 1'b1;
            STATE_WAIT_ACK:
                done      = 1'b1;
            default:
                begin
                    shift_ena = 1'b0;
                    counting  = 1'b0;
                    done      = 1'b0;
                end
        endcase
    end

endmodule