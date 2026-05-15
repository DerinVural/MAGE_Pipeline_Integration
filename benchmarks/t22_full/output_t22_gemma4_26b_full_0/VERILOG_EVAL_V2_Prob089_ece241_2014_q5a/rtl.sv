module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic x,
    output logic z
);

    // State definitions
    localparam logic [1:0] ST_SEARCH    = 2'b00;
    localparam logic [1:0] ST_FIRST_1   = 2'b01;
    localparam logic [1:0] ST_FLIP_0    = 2'b10; // We are in flipping mode, current output is 0
    localparam logic [1:0] ST_FLIP_1    = 2'b11; // We are in flipping mode, current output is 1

    logic [1:0] state;

    // Sequential logic for state transitions
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= ST_SEARCH;
        end else begin
            case (state)
                ST_SEARCH:
                    if (x == 1'b1) begin
                        state <= ST_FIRST_1;
                    end else begin
                        state <= ST_SEARCH;
                    end
                
                ST_FIRST_1:
                    if (x == 1'b0) begin
                        state <= ST_FLIP_1;
                    end else begin
                        state <= ST_FLIP_0;
                    end

                ST_FLIP_0:
                    if (x == 1'b0) begin
                        state <= ST_FLIP_1;
                    end else begin
                        state <= ST_FLIP_0;
                    end

                ST_FLIP_1:
                    if (x == 1'b0) begin
                        state <= ST_FLIP_1;
                    end else begin
                        state <= ST_FLIP_0;
                    end
                
                default: state <= ST_SEARCH;
            endcase
        end
    end

    // Combinational logic for Moore output
    always @(*) begin
        case (state)
            ST_SEARCH:  z = 1'b0;
            ST_FIRST_1: z = 1'b1;
            ST_FLIP_0:  z = 1'b0;
            ST_FLIP_1:  z = 1'b1;
            default:    z = 1'b0;
        endcase
    end

endmodule