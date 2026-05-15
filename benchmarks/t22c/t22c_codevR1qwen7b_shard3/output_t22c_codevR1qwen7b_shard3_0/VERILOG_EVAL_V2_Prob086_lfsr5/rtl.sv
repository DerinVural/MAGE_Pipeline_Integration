module TopModule (input logic clk, input logic reset, output logic [4:0] q);
    // Define states using localparam
    localparam [4:0] STATE0 = 5'b00001;
    localparam [4:0] STATE1 = 5'b00010;
    localparam [4:0] STATE2 = 5'b00100;
    localparam [4:0] STATE3 = 5'b01000;
    localparam [4:0] STATE4 = 5'b10000;

    // Declare state registers
    logic [4:0] state_reg;
    logic [4:0] state_next;

    // Initialize state without reset
    initial begin
        state_reg = STATE0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state_reg <= STATE0;
        end else begin
            state_reg <= state_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        case (state_reg)
            STATE0: state_next = STATE1;
            STATE1: state_next = STATE2;
            STATE2: state_next = STATE3;
            STATE3: state_next = STATE4;
            STATE4: state_next = STATE0;
            default: state_next = STATE0;
        endcase
    end

    // Output assignment
    assign q = state_reg;
endmodule