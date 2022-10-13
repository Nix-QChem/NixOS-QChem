#
# Turn relevant CUDA flags and use latest CUDA toolkit
#
final: prev:

{
  cudatoolkit = prev.cudatoolkit_11;

  mpich = prev.mpich.override {
    ch4backend = final.ucx;
  };

  openmpi = prev.openmpi.override {
    cudaSupport = true;
  };

  ucx = prev.ucx.override {
    enableCuda = true;
  };

  ucc = prev.ucc.override {
    enableCuda = true;
  };
}
