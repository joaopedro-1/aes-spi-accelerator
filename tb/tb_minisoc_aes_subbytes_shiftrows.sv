`timescale 1ns/1ps
// Testbench da semana 2: S-box, SubBytes, ShiftRows e as inversas.
// Os modulos estao em cadeia: state -> SubBytes -> ShiftRows -> InvShiftRows -> InvSubBytes,
// entao no fim da cadeia o estado tem que voltar ao original.
module tb_minisoc_aes_subbytes_shiftrows;

  logic [7:0]   x, sbox_y, inv_y;
  logic [127:0] state, sub, shift, inv_shift, inv_sub;
  int errors = 0;

  minisoc_aes_sbox           u_sbox      (.data_i(x),         .data_o(sbox_y));
  minisoc_aes_inv_sbox       u_inv_sbox  (.data_i(sbox_y),    .data_o(inv_y));
  minisoc_aes_sub_bytes      u_sub       (.state_i(state),     .state_o(sub));
  minisoc_aes_shift_rows     u_shift     (.state_i(sub),       .state_o(shift));
  minisoc_aes_inv_shift_rows u_inv_shift (.state_i(shift),     .state_o(inv_shift));
  minisoc_aes_inv_sub_bytes  u_inv_sub   (.state_i(inv_shift), .state_o(inv_sub));

  // FIPS-197 Apendice B, rodadas 1 a 10
  logic [127:0] start_of_round [10] = '{
    128'h193de3bea0f4e22b9ac68d2ae9f84808,
    128'ha49c7ff2689f352b6b5bea43026a5049,
    128'haa8f5f0361dde3ef82d24ad26832469a,
    128'h486c4eee671d9d0d4de3b138d65f58e7,
    128'he0927fe8c86363c0d9b1355085b8be01,
    128'hf1006f55c1924cef7cc88b325db5d50c,
    128'h260e2e173d41b77de86472a9fdd28b25,
    128'h5a4142b11949dc1fa3e019657a8c040c,
    128'hea835cf00445332d655d98ad8596b0c5,
    128'heb40f21e592e38848ba113e71bc342d2
  };
  logic [127:0] after_subbytes [10] = '{
    128'hd42711aee0bf98f1b8b45de51e415230,
    128'h49ded28945db96f17f39871a7702533b,
    128'hac73cf7befc111df13b5d6b545235ab8,
    128'h52502f2885a45ed7e311c807f6cf6a94,
    128'he14fd29be8fbfbba35c89653976cae7c,
    128'ha163a8fc784f29df10e83d234cd503fe,
    128'hf7ab31f02783a9ff9b4340d354b53d3f,
    128'hbe832cc8d43b86c00ae1d44dda64f2fe,
    128'h87ec4a8cf26ec3d84d4c46959790e7a6,
    128'he9098972cb31075f3d327d94af2e2cb5
  };
  logic [127:0] after_shiftrows [10] = '{
    128'hd4bf5d30e0b452aeb84111f11e2798e5,
    128'h49db873b453953897f02d2f177de961a,
    128'hacc1d6b8efb55a7b1323cfdf457311b5,
    128'h52a4c89485116a28e3cf2fd7f6505e07,
    128'he1fb967ce8c8ae9b356cd2ba974ffb53,
    128'ha14f3dfe78e803fc10d5a8df4c632923,
    128'hf783403f27433df09bb531ff54aba9d3,
    128'hbe3bd4fed4e1f2c80a642cc0da83864d,
    128'h876e46a6f24ce78c4d904ad897ecc395,
    128'he9317db5cb322c723d2e895faf090794
  };

  // Referencia da S-box calculada pela definicao (inverso em GF(2^8) + transformacao afim).
  // Nao usa a tabela do RTL, assim um erro de digitacao na tabela nao passa despercebido.
  function automatic logic [7:0] xtime(logic [7:0] a);
    return {a[6:0], 1'b0} ^ (a[7] ? 8'h1b : 8'h00);
  endfunction

  function automatic logic [7:0] gf_mul(logic [7:0] a, logic [7:0] b);
    logic [7:0] p = '0;
    for (int i = 0; i < 8; i++) begin
      if (b[i]) p ^= a;
      a = xtime(a);
    end
    return p;
  endfunction

  function automatic logic [7:0] ref_sbox(logic [7:0] a);
    logic [7:0] b = '0;  // inverso de a; 0 fica 0
    for (int i = 1; i < 256; i++)
      if (gf_mul(a, 8'(i)) == 8'h01) b = 8'(i);
    return b ^ {b[6:0], b[7]} ^ {b[5:0], b[7:6]} ^ {b[4:0], b[7:5]} ^ {b[3:0], b[7:4]} ^ 8'h63;
  endfunction

  task automatic check(string what, logic [127:0] got, logic [127:0] exp);
    if (got !== exp) begin
      $display("ERRO %s: %0h (esperado %0h)", what, got, exp);
      errors++;
    end
  endtask

  initial begin
    // S-box nas 256 entradas
    for (int i = 0; i < 256; i++) begin
      x = 8'(i);
      #1;
      if (sbox_y !== ref_sbox(x)) begin
        $display("ERRO sbox(%h) = %h (esperado %h)", x, sbox_y, ref_sbox(x));
        errors++;
      end
      if (inv_y !== x) begin
        $display("ERRO inv_sbox(sbox(%h)) = %h", x, inv_y);
        errors++;
      end
    end

    // valores do enunciado
    x = 8'h00; #1; if (sbox_y !== 8'h63) begin $display("ERRO sbox(00) = %h", sbox_y); errors++; end
    x = 8'h53; #1; if (sbox_y !== 8'hed) begin $display("ERRO sbox(53) = %h", sbox_y); errors++; end

    // Apendice B: start of round -> after SubBytes -> after ShiftRows
    for (int r = 0; r < 10; r++) begin
      state = start_of_round[r];
      #1;
      check($sformatf("rodada %0d SubBytes", r + 1),     sub,       after_subbytes[r]);
      check($sformatf("rodada %0d ShiftRows", r + 1),    shift,     after_shiftrows[r]);
      check($sformatf("rodada %0d InvShiftRows", r + 1), inv_shift, sub);
      check($sformatf("rodada %0d InvSubBytes", r + 1),  inv_sub,   state);
    end

    if (errors == 0) $display("TEST PASSED");
    else             $fatal(1, "TEST FAILED: %0d erro(s)", errors);
    $finish;
  end

endmodule
