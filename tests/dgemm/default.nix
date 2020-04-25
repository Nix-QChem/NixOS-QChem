{ batsTest, mt-dgemm
, size ? 500
} :

batsTest {
  name = "dgemm";

  outFile = [ "dgemm.out" ];

  nativeBuildInputs = [ mt-dgemm ];

  testScript = ''
    @test "DGEMM" {
      OMP_NUM_THREADS=$TEST_NUM_CPUS ${mt-dgemm}/bin/mt-dgemm ${toString size} > dgemm.out
    }
  '';
}
