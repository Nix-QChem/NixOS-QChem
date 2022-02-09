{ lib, stdenv, fetchurl, rpmextract, gfortran, autoPatchelfHook, libfabric }:

let
  version = "2021.5.1";
  release = "515";
  baseUrl = "https://yum.repos.intel.com/oneapi";

  oneapi-mpi = fetchurl {
    url = "${baseUrl}/intel-oneapi-mpi-${version}-${version}-${release}.x86_64.rpm";
    sha256 = "04pnqlwz38dibk8ly6lv97vxzi5w7sws520m6ra14d3nbqfaqg1n";
  };

  oneapi-mpi-devel = fetchurl {
    url = "${baseUrl}/intel-oneapi-mpi-devel-${version}-${version}-${release}.x86_64.rpm";
    sha256 = "08q0bwqqwly30k8h4kyhy1v305zah8w0f9290p7ds6i4js0krd85";
  };

in stdenv.mkDerivation {
  pname = "intelmpi";
  version = "${version}-${release}";

  dontUnpack = true;
  dontStrip = true;

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ rpmextract autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib libfabric ];

  buildPhase = ''
    rpmextract ${oneapi-mpi}
    mv opt/intel/oneapi/mpi/${version} out

    rpmextract ${oneapi-mpi-devel}
    mv opt/intel/oneapi/mpi/${version} dev
  '';

  installPhase = ''
    mkdir -p $out $dev

    # install runtime in $out
    install -Dm0755 -t $out/bin out/bin/mpi*
    install -Dm0755 -t $out/bin out/bin/hydra*
    install -Dm0755 -t $out/bin out/bin/impi_info
    install -Dm0755 -t $out/bin out/bin/cpuinfo

    install -Dm0755 -t $out/lib out/lib/*.so*
    install -Dm0755 -t $out/lib out/lib/release/*.so*

    #install -Dm0755 -t $out/bin out/libfabric/bin/*
    #install -Dm0755 -t $out/lib out/libfabric/lib/*.so*
    #cp -r  out/libfabric/lib/prov $out/lib

    install -Dm0644 -t $out/share/doc/intelmpi out/licensing/license.txt

    # install development in $dev
    cp -r dev/include $dev
    install -Dm0644 -t $dev/lib/pkgconfig dev/lib/pkgconfig/impi.pc
    install -Dm0755 -t $dev/bin dev/bin/*

    mkdir -p $dev/share
    cp -r dev/man $out/share
  '';

  preFixup = ''
    # Fix compiler paths
    substituteInPlace $dev/bin/mpicc --replace \
        'default_compiler_name="gcc"' \
        'default_compiler_name="${stdenv.cc}/bin/cc"'

    substituteInPlace $dev/bin/mpicc --replace \
        'default_compiler_name="g++"' \
        'default_compiler_name="${stdenv.cc}/bin/c++"'

    substituteInPlace $dev/bin/mpif77 --replace \
        'F77="gfortran"' \
        'F77="${gfortran}/bin/gfortran"'

    substituteInPlace $dev/bin/mpif90 --replace \
        'FC="gfortran"' \
        'FC="${gfortran}/bin/gfortran"'

    substituteInPlace $dev/bin/mpif77 --replace \
        'default_compiler_name="gfortran"' \
        'default_compiler_name="${gfortran}/bin/gfortran"'

  '';

  meta = with lib; {
    description = "Intel's MPI implementation";
    homepage = "https://www.intel.com/content/www/us/en/developer/tools/oneapi/mpi-library.html";
    license = licenses.issl;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ markuskowa ];
  };
}
