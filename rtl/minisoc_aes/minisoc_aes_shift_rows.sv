`timescale 1ns/1ps
// ShiftRows (FIPS-197, 5.1.2): a linha r do estado gira r bytes para a esquerda.
// O estado e preenchido por coluna, entao o byte n fica na linha n%4 e na coluna n/4:
//
//   s[0] s[4] s[8]  s[12]        s[0]  s[4]  s[8]  s[12]
//   s[1] s[5] s[9]  s[13]   ->   s[5]  s[9]  s[13] s[1]
//   s[2] s[6] s[10] s[14]        s[10] s[14] s[2]  s[6]
//   s[3] s[7] s[11] s[15]        s[15] s[3]  s[7]  s[11]
//
// So troca a posicao dos bytes: nao gera nenhuma porta logica.
module minisoc_aes_shift_rows (
  input  logic [127:0] state_i,
  output logic [127:0] state_o
);

  logic [7:0] s [16];

  for (genvar i = 0; i < 16; i++) begin : gen_bytes
    assign s[i] = state_i[127-8*i -: 8];
  end

  assign state_o = {s[0],  s[5],  s[10], s[15],   // coluna 0
                    s[4],  s[9],  s[14], s[3],    // coluna 1
                    s[8],  s[13], s[2],  s[7],    // coluna 2
                    s[12], s[1],  s[6],  s[11]};  // coluna 3

endmodule
