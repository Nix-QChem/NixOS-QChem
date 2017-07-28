{ stdenv, fetchFromGitHub, gcc, slurm17 } :
let
  version = "0.2.5";
in
  
  stdenv.mkDerivation {
    name = "slurm-spank-x11";
    version = version;

    src = fetchFromGitHub {
      owner = "hautreux"; 
      repo = "slurm-spank-x11";
      rev = version;
      sha256 = "1dmsr7whxcxwnlvl1x4s3bqr5cr6q5ssb28vqi67w5hj4sshisry";
    };

    buildPhase = ''
        gcc -DX11_LIBEXEC_PROG="\"$out/bin/slurm-spank-x11\"" \
            -g -o slurm-spank-x11 slurm-spank-x11.c
        gcc -I${slurm17.dev}/include -DX11_LIBEXEC_PROG="\"$out/bin/slurm-spank-x11\"" -shared -fPIC \
            -g -o x11.so slurm-spank-x11-plug.c
      '';

    installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/lib
        install -m 755 slurm-spank-x11 $out/bin
        install -m 755 x11.so $out/lib
      '';
  }

  

