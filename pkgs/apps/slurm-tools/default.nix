{ stdenvNoCC, lib, fetchFromGitHub } :

stdenvNoCC.mkDerivation rec {
  pname = "slurm-tools";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "markuskowa";
    repo = "slurm-tools";
    rev = version;
    sha256 = "1lhbf2x5arr60jshd78ld6wqfj7xyk920c7csww0285ljr0l89wa";
  };

  installPhase = ''
    mkdir -p $out/bin

    cd src
    for i in *; do
      install -m 755 -t $out/bin $i
    done
  '';

  meta = with lib; {
    description = "Collection of scripts to integrate nix and slurm";
    homepage = "https://github.com/markuskowa/slurm-tools";
    license = licenses.mit;
    maintainers = [ maintainers.markuskowa ];
  };
}
