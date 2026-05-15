module TopModule(
    input logic clk,
    input logic reset,
    input logic s,
    input logic w,
    output logic z
);

    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;

    logic [1:0] state;
    logic [1:0] state_next;
    logic count;
    logic [1:0] count_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_A;
            count_reg <= 0;
        end else begin
            state <= state_next;
            if (count_reg != 3)
                count_reg <= count_reg + w;
        end
    end

    always @(*) begin
        // Reset conditions
        if (reset) begin
            state_next = STATE_A;
            count_reg <= 0;
        end else begin
            // Sequential logic based on current state
            case (state)
                STATE_A: begin
                    if (s)
                        state_next = STATE_B;
                end
                STATE_B: begin
                    // Count increment
                    if (count_reg != 3)
                        count_reg <= count_reg + w;
                    state_next = STATE_C;
                end
                STATE_C: begin
                    // Output determination
                    if (count_reg == 2)
                        z = 1;
                    else
                        z = 0;
                    state_next = STATE_A;
                end
            endcase
        end
    end

endmodule