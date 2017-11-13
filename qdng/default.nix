{ stdenv, fetchgit, gfortran, fftw, protobuf, liblapack, blas,
  automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
}:

let
  rev = "";
in
   stdenv.mkDerivation {
     name = "qdng";
     src = fetchgit {
       url = /home/markus/src/QDng.git;
       rev = "7a2178054096e9dbd45f400b23056d4b348641ea";
       sha256 = "0hgy4dl17f65ns13d2hqxf7a4nj4sm2c6gc9z107y8f91q9j7mw1";
     };
    
     preConfigure = ''
       ./genbs
     '';

     buildInputs = [ gfortran fftw protobuf liblapack 
                     blas bzip2 zlib libxml2
                     flex bison ];
     nativeBuildInputs = [ automake autoconf libtool ];

     meta = {
       description = "Quantum dynamics program package";
       platforms = stdenv.lib.platforms.linux;
       maintainer = "markus.kowalewski@gmail.com";
     };

   }
