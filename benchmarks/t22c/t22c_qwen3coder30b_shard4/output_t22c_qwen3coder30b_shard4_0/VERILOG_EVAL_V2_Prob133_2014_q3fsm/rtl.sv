module TopModule (
    input clk,
    input reset,
    input s,
    input w,
    output z
);

    // Define states
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State and counter variables
    logic [1:0] state;
    logic [1:0] state_next;
    logic [1:0] w_count;
    logic [1:0] w_count_next;
    logic z_next;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_A;
            w_count <= 2'b00;
        end else begin
            state <= state_next;
            w_count <= w_count_next;
        end
    end

    // Combinational logic for next state and output
    always @(*) begin
        case (state)
            STATE_A: begin
                if (s)
                    state_next = STATE_B;
                else
                    state_next = STATE_A;
                w_count_next = 2'b00;
                z_next = 1'b0;
            end

            STATE_B: begin
                if (w)
                    w_count_next = 2'b01;
                else
                    w_count_next = 2'b00;
                state_next = STATE_C;
                z_next = 1'b0;
            end

            STATE_C: begin
                if (w)
                    w_count_next = w_count + 2'b01;
                else
                    w_count_next = w_count;
                state_next = STATE_D;
                z_next = 1'b0;
            end

            STATE_D: begin
                if (w)
                    w_count_next = w_count + 2'b01;
                else
                    w_count_next = w_count;
                if (w_count_next == 2'b10)
                    z_next = 1'b1;
                else
                    z_next = 1'b0;
                state_next = STATE_A;
            end

            default: begin
                state_next = STATE_A;
                w_count_next = 2'b00;
                z_next = 1'b0;
            end
        endcase
    end

    // Assign output
    assign z = z_next;

endmodule