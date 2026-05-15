module TopModule (input logic clk, input logic areset, input logic bump_left, input logic bump_right, output logic walk_left, output logic walk_right);

localparam STATE_LEFT = 1'b0;
localparam STATE_RIGHT = 1'b1;

logic state;
logic next_state;

initial begin
    state = STATE_LEFT;
end

always @(posedge clk or posedge areset) begin
    if (areset) begin
        state <= STATE_LEFT;
    end else begin
        state <= next_state;
    end
end

// Next state logic
always @(*) begin
    case (state)
        STATE_LEFT: begin
            if (bump_left || bump_right) begin
                next_state = STATE_RIGHT;
            end else begin
                next_state = STATE_LEFT;
            end
        end
        STATE_RIGHT: begin
            if (bump_left || bump_right) begin
                next_state = STATE_LEFT;
            end else begin
                next_state = STATE_RIGHT;
            end
        end
        default: next_state = STATE_LEFT;
    endcase
end

// Output logic based on current state
assign walk_left = (state == STATE_LEFT);
assign walk_right = (state == STATE_RIGHT);

endmodule