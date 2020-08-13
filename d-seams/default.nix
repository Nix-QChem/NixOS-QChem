{ clangStdenv, stdenv, fetchurl, catch2, rang, fmt, libyamlcpp, cmake, eigen
, lua, luaPackages, liblapack, blas, lib, boost, gsl ? null }:

clangStdenv.mkDerivation rec {
  version = "v1.0.1";
  pname = "d-SEAMS";

  src = fetchurl {
    url = "https://github.com/d-SEAMS/seams-core/archive/${version}.tar.gz";
    sha256 = "0kqiz0l6ra02w3i15ymwc6v51vc6xzqhj6h7wsd4ri5lcl37n75p";
  };

  enableParallelBuilding = true;
  nativeBuildInputs = [ cmake lua luaPackages.luafilesystem ];
  buildInputs = [ fmt rang libyamlcpp eigen catch2 boost gsl liblapack blas ];

  meta = with stdenv.lib; {
    description =
      "d-SEAMS: Deferred Structural Elucidation Analysis for Molecular Simulations";
    longDescription = ''
      d-SEAMS, is a free and open-source postprocessing engine for the analysis
      of molecular dynamics trajectories, which is specifically able to
      qualitatively classify ice structures in both strong-confinement and bulk
      systems. The engine is in C++, with extensions via the Lua scripting
      interface.
    '';
    homepage = "https://dseams.info";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.HaoZeke ];
  };
}
