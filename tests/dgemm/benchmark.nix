{ callPackage, lib, qc-tests } :

{
  threads ? 1
, size ? 1000
} :

callPackage ../../builders/benchmark.nix {
  test = qc-tests.dgemm.override { inherit size; };

  setupPhase = ''
    export TEST_NUM_CPUS=${toString threads}
    export OMP_NUM_THREADS=1
  '';
}
