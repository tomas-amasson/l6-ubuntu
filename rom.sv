module rom (
  input  logic [31:0] a,
  output logic [31:0] rd);

  logic  [31:0] ROM [0:255];

  // initialize memory with instructions
  initial begin
    $readmemh("../riscv.hex", ROM);
  end

  assign rd = ROM[a[31:2]]; // word aligned
endmodule