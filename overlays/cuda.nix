#
# Turn relevant CUDA flags and use latest CUDA toolkit
#
final: prev:

{
  mpich = prev.mpich.override {
    ch4backend = final.ucx;
  };

  ucx = prev.ucx.override {
    enableCuda = true;
  };

  ucc = prev.ucc.override {
    enableCuda = true;
  };

  hwloc = prev.hwloc.override {
    enableCuda = true;
  };
}
