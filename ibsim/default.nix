{ stdenv, fetchurl, infiniband-diags, rdma-core } :

let
  version = "0.7";

in stdenv.mkDerivation {
  name = "ibsim-${version}";

  src = fetchurl {
    url = "https://www.openfabrics.org/downloads/management/ibsim-${version}.tar.gz";
    sha256 = "091f41vfishmkph325nn7r6mv06jrzlrjjvgkdc6cs6yy1bq5436";
  };

  nativeBuildInputs = [ ];
  buildInputs = [ infiniband-diags rdma-core ];

  buildPhase = ''
    make

    make -C tests
  '';

  installPhase = ''
    make DESTDIR=$out install

    mv  $out/tmp/unknown/* $out
    rm -r $out/tmp

    find $out
    mkdir -p $out/share/doc/ibsim
    cp README $out/share/doc/ibsim
    cp net-examples/* $out/share/doc/ibsim
    cp scripts/* $out/bin

    ls tests
    cp tests/subnet_discover $out/bin
    cp tests/query_many $out/bin
    cp tests/mcast_storm $out/bin

    # convience wrapper
    cat << EOF > $out/bin/ibsim-wrapper
    #!/bin/bash
    LD_PRELOAD=$out/lib/umad2sim/libumad2sim.so \$@
    EOF
    chmod +x $out/bin/ibsim-wrapper
  '';

  meta = with stdenv.lib; {
    description = "Infiniband Fabric Simulator";
    homepage = http://openfabrics.org;
    maintainers = with maintainers; [ markuskowa ];
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}

