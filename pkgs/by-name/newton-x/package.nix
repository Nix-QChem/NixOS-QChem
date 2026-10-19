{ lib
, buildEnv
, fetchFromGitLab
, newtonx-cs
, newtonx-ns
, skitten
, python3
}:

let
  newtonx = import ./common.nix { inherit fetchFromGitLab; };

  python = python3.withPackages (p: with p; [
    legion
    ulamdyn
  ]);

in
buildEnv {
  name = "newton-x-${newtonx.version}";
  paths = [
    newtonx-cs
    newtonx-ns
    skitten
    python
  ];

  meta = with lib; {
    description = "Newton-X: general purpose program for nonadiabatic dynamics";
    homepage = "https://gitlab.com/light-and-molecules/newton-x-package";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
