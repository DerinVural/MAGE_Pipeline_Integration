module TopModule(
    input  logic       in,
    input  logic [3:0] state,
    output logic [3:0] next_state,
    output logic       out
);

    // One-hot state definitions
    localparam logic [3:0] STATE_A = 4'b0001;
    localparam logic [3:0] STATE_B = 4'b0010;
    localparam logic [3:0] STATE_C = 4'b0100;
    localparam logic [3:0] STATE_D = 4'b1000;

    // Combinational logic for next_state
    always @(*) begin
        next_state = 4'b0000;
        if (state == STATE_A) begin
            if (in == 1'b0) next_state = STATE_A;
            else            next_state = STATE_B;
        end
        else if (state == STATE_B) begin
            if (in == 1'b0) next_state = STATE_C;
            else            next_state = STATE_B;
        end
        else if (state == STATE_C) begin
            if (in == 1'b0) next_state = STATE_A;
            else            next_state = STATE_D;
        end
        else if (state == STATE_D) begin
            if (in == 1'b0) next_state = STATE_C;
            else            next_state = STATE_B;
        end
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