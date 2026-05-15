module stimulus_gen (input clk, output logic a, b, c, output logic [511:0] wavedrom_title, output logic wavedrom_enable);
    reg [2:0] state;
    localparam STATE_A = 3'b000;
    localparam STATE_B = 3'b001;
    localparam STATE_C = 3'b010;
    localparam STATE_D = 3'b011;
    localparam STATE_E = 3'b100;
    reg [2:0] state_reg;

    // Initialize signals
    initial begin
        state_reg = STATE_A;
        wavedrom_title = 0;
        wavedrom_enable = 0;
    end

    // State machine
    always @(posedge clk) begin
        case (state_reg)
            STATE_A: begin
                state_reg <= STATE_B;
                {a, b, c} <= $random;
                wavedrom_enable <= 1;
            end
            STATE_B: begin
                state_reg <= STATE_C;
                {a, b, c} <= $random;
            end
            STATE_C: begin
                state_reg <= STATE_D;
                {a, b, c} <= $random;
            end
            STATE_D: begin
                state_reg <= STATE_E;
                {a, b, c} <= $random;
            end
            STATE_E: begin
                state_reg <= STATE_A;
                {a, b, c} <= $random;
                wavedrom_enable <= 0;
            end
            default: state_reg <= STATE_A;
        endcase
    end
endmodule