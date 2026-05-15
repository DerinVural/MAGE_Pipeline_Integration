module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic z
);

    // State register
    logic [2:0] state;
    logic [2:0] next_state;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= 3'b000;
        end else begin
            state <= next_state;
        end
    end

    // Next state combinational logic
    always @(*) begin
        next_state = state;
        case (state)
            3'b000:
                next_state = x ? 3'b001 : 3'b000;
            3'b001:
                next_state = x ? 3'b100 : 3'b001;
            3'b010:
                next_state = x ? 3'b001 : 3'b010;
            3'b011:
                next_state = x ? 3'b010 : 3'b001;
            3'b100:
                next_state = x ? 3'b100 : 3'b011;
            default:
                next_state = 3'b000;
        endcase
    end

    // Output combinational logic
    always @(*) begin
        if (state == 3'b011 || state == 3'b100) begin
            z = 1'b1;
        end else begin
            z = 1'b0;
        end
    end

endmodule