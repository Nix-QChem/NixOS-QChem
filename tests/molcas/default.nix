{ lib, batsTest, molcas, mpi, openssh
, enableMpi ? false
, TEST_NUM_CPUS ? if enableMpi then 2 else 1
, OMP_NUM_THREADS ? if enableMpi then 1 else 2
}:

batsTest {
  name = "molcas${lib.optionalString enableMpi "-mpi"}";
  auxFiles = [ ./molcas.inp ];

  outFile = [ "molcas.out" ];

  nativeBuildInputs = [ molcas openssh ] ++ lib.optional enableMpi mpi;

  inherit TEST_NUM_CPUS OMP_NUM_THREADS;
  numCpus = TEST_NUM_CPUS;

  testScript = lib.optionalString enableMpi ''
    @test "OpenMolcas uses MPI" {
      grep -F "${mpi}/bin/mpiexec" "${molcas}/molcas.rte"
    }
  '' + ''

    @test "Run-Molcas" {
      env > env
      ${molcas}/bin/pymolcas -np $TEST_NUM_CPUS molcas.inp > molcas.out
      grep -F "Happy landing" molcas.out
      ${lib.optionalString enableMpi ''
        grep -F "launched $TEST_NUM_CPUS MPI processes, running in PARALLEL mode (work-sharing enabled)" molcas.out
      ''}
    }

    @test "HF Energy" {
      grep 'Total SCF energy' molcas.out | grep '\-113.9192464'
    }

    @test "CASSCF Energy" {
      grep 'RASSCF root number  1' molcas.out | grep '\-113.9406226'
      grep 'RASSCF root number  2' molcas.out | grep '\-113.7941812'
      grep 'RASSCF root number  3' molcas.out | grep '\-113.5246366'
    }

    @test "CASPT2 Energy" {
      grep 'MS-CASPT2 Root  1' molcas.out | grep '\-114.3443192'
      grep 'MS-CASPT2 Root  2' molcas.out | grep '\-114.1969791'
      grep 'MS-CASPT2 Root  3' molcas.out | grep '\-113.9916607'
    }
  '';
}

