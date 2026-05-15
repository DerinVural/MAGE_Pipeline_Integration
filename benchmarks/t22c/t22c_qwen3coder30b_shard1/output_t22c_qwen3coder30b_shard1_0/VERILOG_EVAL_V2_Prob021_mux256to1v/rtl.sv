module TopModule (
    input  [1023:0] in,
    input  [7:0] sel,
    output [3:0] out
);

    // Calculate the starting bit index for the selected 4-bit chunk
    // Each chunk is 4 bits, so we multiply sel by 4
    assign out = in[(sel << 2) +: 4];

endmodule