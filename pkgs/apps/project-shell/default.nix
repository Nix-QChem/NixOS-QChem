{ lib, stdenvNoCC, jq, niv } :

stdenvNoCC.mkDerivation rec {
  pname = "project-shell";
  version = "0.9";

  src = ./project-shell;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    install -m 755 -T ${src} $out/bin/project-shell
  '';

  preFixup = ''
    sed -i 's:@jq@:${jq}/bin/jq:' $out/bin/project-shell
    sed -i 's:@niv@:${niv}/bin/niv:' $out/bin/project-shell
  '';

  meta = with lib; {
    description = "shell.nix generator";
    maintainers = [ maintainers.markuskowa ];
    license = licenses.mit;
  };
}
