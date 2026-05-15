module TopModule(clk, reset, in, disc, flag, err);
    input logic clk;
    input logic reset;
    input logic in;
    output logic disc;
    output logic flag;
    output logic err;

    localparam STATE_IDLE = 3'b000;
    localparam STATE_ONE = 3'b001;
    localparam STATE_TWO = 3'b010;
    localparam STATE_THREE = 3'b011;
    localparam STATE_FOUR = 3'b100;
    localparam STATE_FIVE = 3'b101;
    localparam STATE_SIX = 3'b110;
    localparam STATE_SEVEN_OR_MORE = 3'b111;

    logic [2:0] state, state_next;

    initial begin
        state = STATE_IDLE;
    end

    always @(posedge clk) begin
        if (reset)
            state <= STATE_IDLE;
        else
            state <= state_next;
    end

    always @(*) begin
        case (state)
            STATE_IDLE: begin
                if (in)
                    state_next = STATE_ONE;
                else
                    state_next = STATE_IDLE;
            end
            STATE_ONE: begin
                if (in)
                    state_next = STATE_TWO;
                else
                    state_next = STATE_IDLE;
            end
            STATE_TWO: begin
                if (in)
                    state_next = STATE_THREE;
                else
                    state_next = STATE_ONE;
            end
            STATE_THREE: begin
                if (in)
                    state_next = STATE_FOUR;
                else
                    state_next = STATE_TWO;
            end
            STATE_FOUR: begin
                if (in)
                    state_next = STATE_FIVE;
                else
                    state_next = STATE_THREE;
            end
            STATE_FIVE: begin
                if (in)
                    state_next = STATE_SIX;
                else
                    state_next = STATE_FOUR;
            end
            STATE_SIX: begin
                if (in)
                    state_next = STATE_SEVEN_OR_MORE;
                else
                    state_next = STATE_FIVE;
            end
            STATE_SEVEN_OR_MORE: begin
                if (!in)
                    state_next = STATE_ONE;
                else
                    state_next = STATE_SEVEN_OR_MORE;
            end
            default: state_next = STATE_IDLE;
        endcase
    end

    assign disc = (state == STATE_SEVEN_OR_MORE || state == STATE_FIVE) && !in;
    assign flag = (state == STATE_SIX); 
    assign err = (state == STATE_SEVEN_OR_MORE);

endmodule