module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic s,
    input  logic w,
    output logic z
);

    // State definitions
    localparam STATE_A  = 2'b00;
    localparam STATE_W1 = 2'b01;
    localparam STATE_W2 = 2'b10;
    localparam STATE_W3 = 2'b11;

    logic [1:0] state;
    logic [1:0] next_state;
    logic [1:0] w_count;
    logic z_reg;

    // Initialize signals to avoid X
    initial begin
        state = STATE_A;
        w_count = 2'b00;
        z_reg = 1'b0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_A;
            w_count <= 2'b00;
            z_reg <= 1'b0;
        end else begin
            state <= next_state;
            
            // Counter and z logic
            if (state == STATE_A) begin
                w_count <= 2'b00;
                z_reg <= 1'b0;
            end else if (state == STATE_W1) begin
                w_count <= w ? 2'b01 : 2'b00;
                z_reg <= 1'b0;
            end else if (state == STATE_W2) begin
                w_count <= (w ? 2'b01 : 2'b00) + w_count;
                z_reg <= 1'b0;
            end else if (state == STATE_W3) begin
                // In state W3, we are observing the 3rd bit.
                // The output z is set in the cycle AFTER the 3rd bit is observed.
                // Therefore, we calculate the final count here.
                // We use a temporary variable logic to check the sum of current w_count and the new w.
                if ((w_count + (w ? 2'b01 : 2'b00)) == 2'b10) begin
                    z_reg <= 1'b1;
                end else begin
                    z_reg <= 1'b0;
                end
                // Reset count for the next window in the next cycle
                w_count <= 2'b00;
            end else begin
                z_reg <= 1'b0;
                w_count <= 2'b00;
            end
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = state;
        case (state)
            STATE_A:
                if (s == 1'b1) next_state = STATE_W1;
                else           next_state = STATE_A;
            STATE_W1:
                next_state = STATE_W2;
            STATE_W2:
                next_state = STATE_W3;
            STATE_W3:
                next_state = STATE_W1;
            default:
                next_state = STATE_A;
        endcase
    end

    // Output assignment
    assign z = z_reg;

endmodule