module TopModule (
    input  logic [1023:0] in,
    input  logic [7:0] sel,
    output logic [3:0] out
);

    // Calculate the starting bit index for the selected 4-bit chunk.
    // Max index required is 255 * 4 = 1020.
    logic [10:0] start_index;

    always @(*)
    begin
        // Calculate the starting bit index
        start_index = sel * 4;

        // Extract the 4 bits starting at start_index using bitwise shift and mask.
        // 1. Right shift 'in' by 'start_index' bits.
        // 2. Mask with 4'hF (binary 1111) to isolate the lowest 4 bits.
        out = in >> start_index & 4'hF;
    end

endmodule