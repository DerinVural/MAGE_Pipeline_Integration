module TopModule (
  input logic clk,
  input logic areset,
  input logic bump_left,
  input logic bump_right,
  input logic ground,
  input logic dig,
  output logic walk_left,
  output logic walk_right,
  output logic aaah,
  output logic digging
);

localparam STATE_WALK_LEFT = 2'b00;
localparam STATE_WALK_RIGHT = 2'b01;
localparam STATE_FALLING = 2'b10;
localparam STATE_SPLAT = 2'b11;

logic [1:0] state;
always @(posedge clk or posedge areset) begin
  if (areset)
    state <= STATE_WALK_LEFT;
  else
    state <= state_next;
end

logic [1:0] state_next;
always @(*) begin
  state_next = state;
  case(state)
    STATE_WALK_LEFT: begin
      if (bump_left) state_next = STATE_WALK_RIGHT;
      else if (bump_right) state_next = STATE_WALK_LEFT;
      else if (dig && ground) state_next = STATE_WALK_RIGHT; // Corrected the state transition for dig
      else if (!ground) state_next = STATE_FALLING;
    end
    STATE_WALK_RIGHT: begin
      if (bump_left) state_next = STATE_WALK_LEFT;
      else if (bump_right) state_next = STATE_WALK_RIGHT;
      else if (dig && ground) state_next = STATE_WALK_RIGHT; // Corrected the state transition for dig
      else if (!ground) state_next = STATE_FALLING;
    end
    STATE_FALLING: begin
      if (ground) state_next = STATE_SPLAT;
      else state_next = STATE_FALLING;
    end
    STATE_SPLAT: state_next = STATE_SPLAT;
    default: state_next = STATE_WALK_LEFT;
  endcase
end

assign walk_left = state == STATE_WALK_LEFT;
assign walk_right = state == STATE_WALK_RIGHT;
assign aaah = state == STATE_FALLING;

// Initialize the 'digging' signal to 0 outside the module
initial begin
digging = 1'b0; // This initialization ensures that 'digging' starts at 0 when the simulation begins
end

endmodule