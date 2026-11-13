`timescale 1ns/1ps
// Expansao de chave AES-128 (FIPS-197 5.2).
// Pre-computada: carrega K0 no start e gera K1..K10, uma por ciclo. As 11 chaves ficam
// guardadas e sao lidas por rnd_i (a decifra le de 10 ate 0).
module minisoc_aes_key_exp (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,
  input  logic [127:0] key_i,
  input  logic [3:0]   rnd_i,
  output logic [127:0] rk_o,
  output logic         ready_o
);

  function automatic logic [7:0] xtime(logic [7:0] b);
    return {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
  endfunction

  logic [127:0] rk_q [11];
  logic [3:0]   cnt_q;    // ultima chave calculada
  logic [7:0]   rcon_q;
  logic         busy_q, ready_q;

  logic [31:0] w0, w1, w2, w3, rot, sub, temp, n0, n1, n2, n3;

  assign {w0, w1, w2, w3} = rk_q[cnt_q];
  assign rot = {w3[23:0], w3[31:24]};

  // SubWord
  for (genvar i = 0; i < 4; i++) begin : gen_sbox
    minisoc_aes_sbox u_sbox (
      .data_i (rot[31-8*i -: 8]),
      .data_o (sub[31-8*i -: 8])
    );
  end

  assign temp = sub ^ {rcon_q, 24'h0};
  assign n0 = w0 ^ temp;
  assign n1 = w1 ^ n0;
  assign n2 = w2 ^ n1;
  assign n3 = w3 ^ n2;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_q   <= '0;
      rcon_q  <= 8'h01;
      busy_q  <= 1'b0;
      ready_q <= 1'b0;
    end else if (start_i) begin
      cnt_q   <= '0;
      rcon_q  <= 8'h01;
      busy_q  <= 1'b1;
      ready_q <= 1'b0;
    end else if (busy_q) begin
      cnt_q  <= cnt_q + 4'd1;
      rcon_q <= xtime(rcon_q);
      if (cnt_q == 4'd9) begin
        busy_q  <= 1'b0;
        ready_q <= 1'b1;
      end
    end
  end

  // chaves nao precisam de reset, ready_o indica quando valem
  always_ff @(posedge clk) begin
    if (start_i)     rk_q[0]            <= key_i;
    else if (busy_q) rk_q[cnt_q + 4'd1] <= {n0, n1, n2, n3};
  end

  assign rk_o    = (rnd_i <= 4'd10) ? rk_q[rnd_i] : '0;
  assign ready_o = ready_q;

endmodule
