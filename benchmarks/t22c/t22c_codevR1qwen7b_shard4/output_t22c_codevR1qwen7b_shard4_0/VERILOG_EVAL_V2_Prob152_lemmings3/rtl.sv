module TopModule (input logic clk, input logic areset, input logic bump_left, bump_right, ground, dig, output logic walk_left, walk_right, aaah, digging);

  // State definitions
  localparam STATE_WALK_LEFT = 0;
  localparam STATE_WALK_RIGHT = 1;
  localparam STATE_FALLING = 2;
  localparam STATE_DIGGING = 3;

  // State and next state registers
  logic [1:0] state, next_state;

  // Output registers
  logic aaah_reg, digging_reg;
  logic walk_left_reg, walk_right_reg;

  // Initialize outputs and state on reset
  initial begin
    walk_left_reg = 1'b1;
    walk_right_reg = 1'b0;
    aaah_reg = 0;
    digging_reg = 0;
    state = STATE_WALK_LEFT;
  end

  // Sequential state transition
  always @(posedge clk or posedge areset) begin
    if (areset) begin
      state <= STATE_WALK_LEFT;
      walk_left_reg <= 1'b1;
      walk_right_reg <= 1'b0;
      aaah_reg <= 0;
      digging_reg <= 0;
    end else begin
      state <= next_state;
    end
  end

  // Combinational next state and outputs
  always @(*) begin
    // Default assignments
    next_state = state;
    walk_left_reg = walk_left_reg;
    walk_right_reg = walk_right_reg;
    aaah_reg = aaah_reg;
    digging_reg = digging_reg;

    case (state)
      STATE_WALK_LEFT: begin
        if (!ground) begin
          next_state = STATE_FALLING;
          aaah_reg = 1'b1;
        end else if (dig && ground) begin
          next_state = STATE_DIGGING;
          digging_reg = 1'b1;
        end else if (bump_left || bump_right) begin
          next_state = STATE_WALK_RIGHT;
          walk_right_reg = 1'b1;
          walk_left_reg = 1'b0;
        end
      end
      STATE_WALK_RIGHT: begin
        if (!ground) begin
          next_state = STATE_FALLING;
          aaah_reg = 1'b1;
        end else if (dig && ground) begin
          next_state = STATE_DIGGING;
          digging_reg = 1'b1;
        end else if (bump_left || bump_right) begin
          next_state = STATE_WALK_LEFT;
          walk_left_reg = 1'b1;
          walk_right_reg = 1'b0;
        end
      end
      STATE_FALLING: begin
        aaah_reg = 1'b1;
        if (ground) begin
          next_state = state; // Resume original direction
        end
      end
      STATE_DIGGING: begin
        if (!ground) begin
          next_state = STATE_FALLING;
          aaah_reg = 1'b1;
        end else if (dig && ground) begin
          digging_reg = 1'b1;
        end else if (ground && !dig) begin
          next_state = state; // Continue digging
        end else if (!ground) begin
          next_state = STATE_FALLING;
        end
      end
      default: begin
        next_state = STATE_WALK_LEFT;
      end
    endcase
  end

  // Assign outputs
  assign walk_left = walk_left_reg;
  assign walk_right = walk_right_reg;
  assign aaah = aaah_reg;
  assign digging = digging_reg;

endmodule