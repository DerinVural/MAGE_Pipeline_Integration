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

    localparam WALK_LEFT = 1'b0;
    localparam WALK_RIGHT = 1'b1;

    logic [1:0] state;
    logic [1:0] state_next;
    logic [3:0] output_reg;

    initial begin
        state <= WALK_LEFT;
        output_reg <= 4'b0000;
    end

    always @(posedge clk) begin
        if (areset)
            state <= WALK_LEFT;
        else
            state <= state_next;
    end

    always @(*) begin
        state_next = state;
        output_reg = output_reg;

        case(state)
            WALK_LEFT:
                begin
                    walk_left = 1'b1;
                    walk_right = 1'b0;
                    aaah = 1'b0;
                    digging = 1'b0;

                    if (bump_left)
                        state_next = WALK_RIGHT;
                    else if (bump_right)
                        state_next = WALK_LEFT;

                    if (!ground)
                        begin
                            state_next = WALK_LEFT;
                            aaah = 1'b1;
                        end
                end
            WALK_RIGHT:
                begin
                    walk_left = 1'b0;
                    walk_right = 1'b1;
                    aaah = 1'b0;
                    digging = 1'b0;

                    if (bump_left)
                        state_next = WALK_LEFT;
                    else if (bump_right)
                        state_next = WALK_RIGHT;

                    if (!ground)
                        begin
                            state_next = WALK_RIGHT;
                            aaah = 1'b1;
                        end
                end
        endcase
    end

    always @(posedge clk) begin
        if (!areset) begin
            walk_left <= 1'b0;
            walk_right <= 1'b0;
            aaah <= 1'b0;
            digging <= 1'b0;
        end else begin
            walk_left <= output_reg[0];
            walk_right <= output_reg[1];
            aaah <= output_reg[2];
            digging <= output_reg[3];
        end
    end

endmodule;