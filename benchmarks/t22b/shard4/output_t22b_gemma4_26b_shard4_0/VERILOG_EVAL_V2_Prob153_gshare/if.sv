interface TopModuleInterface(input logic clk, input logic areset);
    input  logic predict_valid;
    input  logic [6:0] predict_pc;
    output logic predict_taken;
    output logic [6:0] predict_history;

    input  logic train_valid;
    input  logic train_taken;
    input  logic train_mispredicted;
    input  logic [6:0] train_history;
    input  logic [6:0] train_pc;
endinterface