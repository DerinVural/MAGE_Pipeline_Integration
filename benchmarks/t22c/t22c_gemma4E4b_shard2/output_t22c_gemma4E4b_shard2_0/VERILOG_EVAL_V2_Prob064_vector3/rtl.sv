module TopModule (
    input  logic [4:0] a,
    input  logic [4:0] b,
    input  logic [4:0] c,
    input  logic [4:0] d,
    input  logic [4:0] e,
    input  logic [4:0] f,
    output logic [7:0] w,
    output logic [7:0] x,
    output logic [7:0] y,
    output logic [7:0] z
);

    // 1. Concatenate inputs: {a, b, c, d, e, f} results in 5*6 = 30 bits.
    // 2. Append two '1' bits (LSBs): 2'b1 is treated as 2 bits {1, 1} if it were the LSB pair, 
    // but since we are appending to 30 bits, we append {1'b1, 1'b1} or simply 2'b1 if the compiler handles it as two LSBs.
    // To explicitly ensure two '1' bits at LSB: {a, b, c, d, e, f, 2'b1} is interpreted as {a..f, b_lsb, a_lsb} which is incorrect.
    // We must use {a, b, c, d, e, f, 2'b1} where 2'b1 is the LSB pair.
    
    // The correct way to append two LSBs of value 1 is: {a, b, c, d, e, f, 2'b1}
    // If we treat 2'b1 as the LSB pair (bit 1 and bit 0), the total width is 32.
    wire [31:0] full_output;
    
    // Concatenation: [31:2: 5*5=25 bits] are the inputs. [1:0] are the two '1's.
    // The input bits occupy [31:2]
    assign full_output = {a, b, c, d, e, f, 2'b1};

    // 3. Split the 32-bit vector into four 8-bit outputs:
    // W: MSB 8 bits [31:24]
    assign w = full_output[31:24];
    // X: next 8 bits [23:16]
    assign x = full_output[23:16];
    // Y: next 8 bits [15:8]
    assign y = full_output[15:8];
    // Z: LSB 8 bits [7:0]
    assign z = full_output[7:0];

endmodule