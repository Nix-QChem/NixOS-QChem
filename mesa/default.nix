{ stdenv, requireFile, gfortran, openblas } :

let
  # I am guessing here, that's the timestamp of the README
  version = "20140610";

in stdenv.mkDerivation {
  name = "mesa-${version}";

  src = requireFile {
    name = "mesa_lucchese.tar.xz";
    sha256 = "0xp287r53xfvgcfv1c2kpl68wsvmfkh1vb0f3l941jb0ry4wh5w0";
  };

  buildInputs = [ gfortran openblas ];

  # prepare for building the ILP64 version
  postPatch = ''
    sed -i 's/BLASUSE=.*/BLASUSE=-lopenblas/' include/appleAbsoft11.gfi8.sh
    patchShebangs ./
  '';

  buildPhase = ''
    ./Makemesa.sh all appleAbsoft11.gfi8
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/mesa

    cp binappleAbsoft11.gfi8/* $out/bin
    cp mesa.dat $out/share/mesa

    cat << EOF > $out/bin/mesa
    #!/bin/bash
    cp $out/share/mesa/mesa.dat .
    mkdir -p tmp
    $out/bin/optmesa \$@
    EOF

    chmod +x $out/bin/mesa
  '';

  meta = with stdenv.lib; {
    description = "Electronic structure and scattering program";
    license = licenses.unfree;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}

