module TopModule (
    input  logic [1023:0] in,
    input  logic [7:0] sel,
    output logic [3:0] out
);

logic [3:0] decoded_out;

// Decode the selector to choose the correct 4-bit segment
always @(*) begin
    case (sel)
        8'd0:  decoded_out = in[3:0];
        8'd1:  decoded_out = in[7:4];
        8'd2:  decoded_out = in[11:8];
        8'd3:  decoded_out = in[15:12];
        8'd4:  decoded_out = in[19:16];
        8'd5:  decoded_out = in[23:20];
        8'd6:  decoded_out = in[27:24];
        8'd7:  decoded_out = in[31:28];
        default: decoded_out = 4'd0;
    endcase
end

// Assign the decoded output to the final output
assign out = decoded_out;

endmodule