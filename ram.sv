module ram (
  input  logic        clk, we,
  input  logic [31:0] a, wd,
  output logic [31:0] rd);

  logic  [31:0] RAM [0:255];

  // initialize memory with data
  initial begin
    RAM[0] = 32'h00000000;
    RAM[1] = 32'h00000001;
  end

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we)
      RAM[a[31:2]] <= wd;
endmodule