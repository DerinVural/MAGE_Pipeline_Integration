module TopModule ( 
    input logic [3:0] x, 
    input logic [3:0] y, 
    output logic [4:0] sum 
);

    // Implementation using SystemVerilog arithmetic operator.
    // Since x and y are 4-bit, their sum can be up to 15 + 15 = 30 (11110 in binary), 
    // requiring 5 bits to correctly capture the carry/overflow into sum[4].
    assign sum = x + y;

endmodule