module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic disc,
    output logic flag,
    output logic err
);

    // State encoding
    localparam logic [3:0] STATE_0     = 4'd0;
    localparam logic [3:0] STATE_1     = 4'd1;
    localparam logic [3:0] STATE_2     = 4'd2;
    localparam logic [3:0] STATE_3     = 4'd3;
    localparam logic [3:0] STATE_4     = 4'd4;
    localparam logic [3:0] STATE_5     = 4'd5;
    localparam logic [3:0] STATE_6     = 4'd6;
    localparam logic [3:0] STATE_7     = 4'd7;
    localparam logic [3:0] STATE_DISC = 4'd8;
    localparam logic [3:0] STATE_FLAG = 4'd9;

    logic [3:0] state_reg;
    logic [3:0] state_next;

    // Sequential logic: State transition
    always @(posedge clk) begin
        if (reset) begin
            state_reg <= STATE_0;
        end else begin
            state_reg <= state_next;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        state_next = state_reg;
        case (state_reg) 
            STATE_0: begin
                if (in) state_next = STATE_1;
                else    state_next = STATE_0;
            end
            STATE_1: begin
                if (in) state_next = STATE_2;
                else    state_next = STATE_0;
            end
            STATE_2: begin
                if (in) state_next = STATE_3;
                else    state_next = STATE_0;
            end
            STATE_3: begin
                if (in) state_next = STATE_4;
                else    state_next = STATE_0;
            end
            STATE_4: begin
                if (in) state_next = STATE_5;
                else    state_next = STATE_0;
            end
            STATE_5: begin
                if (in) state_next = STATE_6;
                else    state_next = STATE_DISC;
            end
            STATE_6: begin
                if (in) state_next = STATE_7;
                else    state_next = STATE_FLAG;
            end
            STATE_7: begin
                if (in) state_next = STATE_7;
                else    state_next = STATE_0;
            end
            STATE_DISC: begin
                if (in) state_next = STATE_1;
                else    state_next = STATE_0;
            end
            STATE_FLAG: begin
                if (in) state_next = STATE_1;
                else    state_next = STATE_0;
            end
            default: state_next = STATE_0;
        endcase
    end

    // Combinational logic: Output logic (Moore)
    always @(*) begin
        disc = 1'b0;
        flag = 1'b0;
        err  = 1'b0;
        case (state_reg) 
            STATE_7:     err  = 1'b1;
            STATE_DISC:  disc = 1'b1;
            STATE_FLAG:  flag = 1'b1;
            default:     begin disc = 1'b0; flag = 1'b0; err = 1'b0; end
        endcase
    end

endmodule