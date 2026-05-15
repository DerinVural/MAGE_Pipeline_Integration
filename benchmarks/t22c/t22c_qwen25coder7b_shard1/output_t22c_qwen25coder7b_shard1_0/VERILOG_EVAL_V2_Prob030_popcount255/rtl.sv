module TopModule (
    input  logic [254:0] in,
    output logic [7:0] out
);

    localparam WIDTH = 255;
    localparam int STAGE_WIDTHS [] = {128, 64, 32, 16};

    logic [WIDTH-1:0] sum1;
    logic [STAGE_WIDTHS[0]-1:0] sum2;
    logic [STAGE_WIDTHS[1]-1:0] sum3;
    logic [STAGE_WIDTHS[2]-1:0] sum4;
    logic [STAGE_WIDTHS[3]+0:0] sum5;

    initial begin
        sum1 = 0;
        sum2 = 0;
        sum3 = 0;
        sum4 = 0;
        sum5 = 0;
    end

    // First stage: Sum pairs of bits
    for (integer i = 0; i < STAGE_WIDTHS[0]; i++) begin
        assign sum1[i] = in[2*i] + in[2*i+1];
    end

    // Second stage: Sum quarters of bits
    for (integer i = 0; i < STAGE_WIDTHS[1]; i++) begin
        assign sum2[i] = sum1[2*i] + sum1[2*i+1];
    end

    // Third stage: Sum eighths of bits
    for (integer i = 0; i < STAGE_WIDTHS[2]; i++) begin
        assign sum3[i] = sum2[2*i] + sum2[2*i+1];
    end

    // Fourth stage: Sum sixteenths of bits
    for (integer i = 0; i < STAGE_WIDTHS[3]; i++) begin
        assign sum4[i] = sum3[2*i] + sum3[2*i+1];
    end

    // Fifth stage: Sum thirty-seconds of bits
    for (integer i = 0; i < STAGE_WIDTHS[3]+1; i++) begin
        assign sum5[i] = sum4[2*i] + sum4[2*i+1];
    end

    // Final addition to produce the population count
    assign out = sum5[0] + sum5[1] + sum5[2] + sum5[3] + sum5[4] + sum5[5] + sum5[6] + sum5[7];

endmodule