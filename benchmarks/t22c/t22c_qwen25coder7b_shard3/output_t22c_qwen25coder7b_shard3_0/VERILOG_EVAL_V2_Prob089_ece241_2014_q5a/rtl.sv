module TopModule (
    logic clk,
    logic areset,
    logic x,
    logic z,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    localparam STATE_IDLE = 2'b00;
    localparam STATE_COMPLEMENT = 2'b01;

    logic [1:0] state = STATE_IDLE;
    logic [1:0] state_next;
    logic [1:0] temp_state;

    always_ff @(posedge clk or posedge areset) begin
        if (areset)
            state <= STATE_IDLE;
        else
            state <= state_next;
    end

    always_comb begin
        state_next = state;
        temp_state = state;

        case(state)
            STATE_IDLE: begin
                if(x)
                    state_next = STATE_COMPLEMENT;
            end
            STATE_COMPLEMENT: begin
                state_next = STATE_IDLE;
                z = ~temp_state & 1'b1;
            end
        endcase
    end

    assign wavedrom_title = "Serial 2's Complementer";
    assign wavedrom_enable = 1'b1;

endmodule