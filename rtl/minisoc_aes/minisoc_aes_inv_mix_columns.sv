`timescale 1ns/1ps
// InvMixColumns (FIPS-197 5.3.3).
// Em vez de multiplicar por 0e, 0b, 0d e 09, faz um pre-passo com 04 e reaproveita o
// MixColumns (livro "The Design of Rijndael", secao 4.1.3).
module minisoc_aes_inv_mix_columns (
  input  logic [127:0] state_i,
  output logic [127:0] state_o
);

  function automatic logic [7:0] xtime(logic [7:0] b);
    return {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
  endfunction

  logic [127:0] pre;

  for (genvar c = 0; c < 4; c++) begin : gen_col
    logic [7:0] s0, s1, s2, s3, u, v;

    assign {s0, s1, s2, s3} = state_i[127-32*c -: 32];
    assign u = xtime(xtime(s0 ^ s2));  // 04.(s0^s2)
    assign v = xtime(xtime(s1 ^ s3));  // 04.(s1^s3)

    assign pre[127-32*c -: 32] = {s0 ^ u, s1 ^ v, s2 ^ u, s3 ^ v};
  end

  minisoc_aes_mix_columns u_mix_columns (
    .state_i (pre),
    .state_o (state_o)
  );

endmodule
