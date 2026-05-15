module TopModule (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [15:0] c,
    input  logic [15:0] d,
    input  logic [15:0] e,
    input  logic [15:0] f,
    input  logic [15:0] g,
    input  logic [15:0] h,
    input  logic [15:0] i,
    input  logic [3:0] sel,
    output logic [15:0] out
);

    // 16-bit wide 9-to-1 Multiplexer implementation using combinational logic
    always @* begin
        case (sel)
            4'h0: out = a;
            4'h1: out = b;
            4'h2: out = c;
            4'h3: out = d;
            4'h4: out = e;
            4'h5: out = f;
            4'h6: out = g;
            4'h7: out = h;
            4'h8: out = i;
            // Default case covers sel = 9 (1001) through sel = 15 (1111)
            default: out = 16'hFFFF;
        endcase
    end

endmodule