{ stdenv, fetchurl, symlinkJoin, gfortran, perl, procps,
  libyaml, arpackng,
  libxc, fftw, blas, liblapack, gsl
}:

let 
  version = "7.1";
  fftwall = symlinkJoin { name ="ftw-dev-out"; paths = [ fftw.dev fftw.out ]; };
in 
  stdenv.mkDerivation {
    name = "octopus-${version}";
    src = fetchurl {
      url = "http://www.tddft.org/programs/octopus/down.php?file=${version}/octopus-${version}.tar.gz";
      sha256 = "0b70dvk6lz8dg9ffm55pbic12hkbxvipggckaicb2siq7zqj611v";
    };

    doCheck = true;
    checkTarget = "check-short";

    configureFlags = ''
      --with-yaml-prefix=${libyaml}
      --with-arpack=${arpackng}/lib/libarpack.a
      --with-blas=${blas}/lib/libblas.a
      --with-lapack=${liblapack}/lib/liblapack.a
      --with-fftw-prefix=${fftwall}
      --with-gsl-prefix=${gsl}
      --with-libxc-prefix=${libxc}
    '';

    buildInputs = [ libyaml gfortran libxc arpackng blas liblapack gsl ];
    nativeBuildInputs = [ perl procps ];

    meta = {
      description = "Real-space time dependent density-functional theory code";
      homepage = http://octopus-code.org/wiki/Libxc;
      licenses = stdenv.lib.licenses.gpl3;
      platforms = stdenv.lib.platforms.linux;
    };
  }
