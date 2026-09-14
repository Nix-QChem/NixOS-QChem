{ batsTest, molcasMPI, mpi, openssh }:

batsTest {
  name = "molcas-mpi";

  auxFiles = [ ./molcas.inp ];

  outFile = [ "molcas-mpi.out" ];

  nativeBuildInputs = [ molcasMPI mpi openssh ];

  TEST_NUM_CPUS=2;
  OMP_NUM_THREADS = 1;

  testScript = ''
    @test "OpenMolcas runtime uses the package MPI" {
      grep -F "${mpi}/bin/mpiexec" "${molcasMPI}/molcas.rte"
    }

    @test "Run OpenMolcas with two MPI ranks" {
      ${molcasMPI}/bin/pymolcas -np 2 molcas.inp > molcas-mpi.out
      grep -F "launched 2 MPI processes, running in PARALLEL mode (work-sharing enabled)" molcas-mpi.out
      grep -F "Happy landing" molcas-mpi.out
    }

    @test "MPI HF energy" {
      grep 'Total SCF energy' molcas-mpi.out | grep '\-113.9192464'
    }

    @test "MPI RASSCF energies" {
      grep 'RASSCF root number  1' molcas-mpi.out | grep '\-113.9406226'
      grep 'RASSCF root number  2' molcas-mpi.out | grep '\-113.7941812'
      grep 'RASSCF root number  3' molcas-mpi.out | grep '\-113.5246366'
    }

    @test "MPI CASPT2 energies" {
      grep 'MS-CASPT2 Root  1' molcas-mpi.out | grep '\-114.3443192'
      grep 'MS-CASPT2 Root  2' molcas-mpi.out | grep '\-114.1969791'
      grep 'MS-CASPT2 Root  3' molcas-mpi.out | grep '\-113.9916607'
    }
  '';
}
