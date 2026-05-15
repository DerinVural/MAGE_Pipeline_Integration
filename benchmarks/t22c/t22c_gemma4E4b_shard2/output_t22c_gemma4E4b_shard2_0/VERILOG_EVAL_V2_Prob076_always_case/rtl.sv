module TopModule (
    input  logic [2:0] sel,
    input  logic [3:0] data0,
    input  logic [3:0] data1,
    input  logic [3:0] data2,
    input  logic [3:0] data3,
    input  logic [3:0] data4,
    input  logic [3:0] data5,
    output logic [3:0] out
);

    // Implementation of the 6-to-1 multiplexer.
    // If sel is 0 through 5, select the corresponding data input.
    // If sel is 6 (110) or 7 (111), output 4'b0000.
    assign out = (sel == 3'b000) ? data0 : 
                 (sel == 3'b001) ? data1 : 
                 (sel == 3'b010) ? data2 : 
                 (sel == 3'b011) ? data3 : 
                 (sel == 3'b100) ? data4 : 
                 (sel == 3'b101) ? data5 : 4'b0000;

endmodule