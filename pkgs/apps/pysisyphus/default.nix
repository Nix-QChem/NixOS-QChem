{ fetchPypi, fetchFromGitHub, buildPythonPackage, lib, writeTextFile, writeScript, makeWrapper
, pytestCheckHook
# Python dependencies
, autograd, dask, distributed, h5py, jinja2, matplotlib, numpy, natsort, pytest, pyyaml, rmsd, scipy
, sympy, scikit-learn, qcengine, ase, xtb-python, openbabel-bindings, pyscf
# Runtime dependencies
, runtimeShell
, jmol, enableJmol ? true
, multiwfn, enableMultiwfn ? false
, xtb, enableXtb ? true
, openmolcas, enableOpenmolcas ? true
, psi4, enablePsi4 ? true
, wfoverlap, enableWfoverlap ? true
, nwchem, enableNwchem ? true
, orca, enableOrca ? false
, turbomole, enableTurbomole ? false
, gaussian, enableGaussian ? false
, cfour, enableCfour ? false
, molpro, enableMolpro ? false
, gamess-us, enableGamess ? false
# Test dependencies
, openssh
# Configuration
, fullTest ? false
}:
let
  psi4Wrapper = writeScript "psi4.sh" ''
    #!${runtimeShell}
    ${psi4}/bin/psi4 -o stdout $1
  '';
  pysisrc =
    let
      gaussian16Conf = {
        cmd = "${gaussian}/bin/g16";
        formchk_cmd = "${gaussian}/bin/formchk";
        unfchk_cmd = "${gaussian}/bin/unfchk";
      };
      text = lib.generators.toINI {} (builtins.listToAttrs ([ ]
        ++ lib.optional enableOpenmolcas { name = "openmolcas"; value.cmd = "${openmolcas}/bin/pymolcas"; }
        ++ lib.optional enablePsi4 { name = "psi4"; value.cmd = "${psi4Wrapper}"; }
        ++ lib.optional enableWfoverlap { name = "wfoverlap"; value.cmd = "${wfoverlap}/bin/wfoverlap.x"; }
        ++ lib.optional enableMultiwfn { name = "multiwfn"; value.cmd = "${multiwfn}/bin/Multiwfn"; }
        ++ lib.optional enableJmol { name = "jmol"; value.cmd = "${jmol}/bin/jmol"; }
        ++ lib.optional enableXtb { name = "xtb"; value.cmd = "${xtb}/bin/xtb"; }
        ++ lib.optional enableGaussian { name = "gaussian16"; value = gaussian16Conf; }
        ++ lib.optional enableOrca { name = "orca"; value.cmd = "${orca}/bin/orca"; }
        ++ lib.optional enableGamess { name = "gamess"; value.cmd = "${gamess-us}/bin/rungms"; }
      ));
    in
      writeTextFile {
        inherit text;
        name = "pysisrc";
      };

  binSearchPath = lib.makeSearchPath "bin" ([ ]
    ++ lib.optional enableJmol jmol
    ++ lib.optional enableMultiwfn multiwfn
    ++ lib.optional enableXtb xtb
    ++ lib.optional enableOpenmolcas openmolcas
    ++ lib.optional enablePsi4 psi4
    ++ lib.optional enableWfoverlap wfoverlap
    ++ lib.optional enableNwchem nwchem
    ++ lib.optional enableOrca orca
    ++ lib.optional enableTurbomole turbomole
    ++ lib.optional enableGaussian gaussian
    ++ lib.optional enableCfour cfour
    ++ lib.optional enableMolpro molpro
    ++ lib.optional enableGamess gamess-us
  );

in
  buildPythonPackage rec {
    pname = "pysisyphus";
    version = "0.7.4";

    nativeBuildInputs = [ makeWrapper ];

    propagatedBuildInputs = [
      autograd
      dask
      distributed
      h5py
      jinja2
      matplotlib
      numpy
      natsort
      pyyaml
      rmsd
      scipy
      sympy
      scikit-learn
      qcengine
      ase
      openbabel-bindings
      openssh
      pyscf
    ] # Syscalls
      ++ lib.optional enableXtb xtb-python
      ++ lib.optional enableXtb xtb
      ++ lib.optional enableJmol jmol
      ++ lib.optional enableMultiwfn multiwfn
      ++ lib.optional enableOpenmolcas openmolcas
      ++ lib.optional enablePsi4 psi4
      ++ lib.optional enableWfoverlap wfoverlap
      ++ lib.optional enableNwchem nwchem
      ++ lib.optional enableOrca orca
      ++ lib.optional enableTurbomole turbomole
      ++ lib.optional enableGaussian gaussian
      ++ lib.optional enableCfour cfour
      ++ lib.optional enableMolpro molpro
      ++ lib.optional enableGamess gamess-us
    ;

    src = fetchFromGitHub {
      owner = "eljost";
      repo = pname;
      rev = version;
      hash = "sha256-CGV/vqeFiG5DYb6w6rQ7rwTPeE9DL8891fXraSWn2Rs=";
    };

    format = "pyproject";

    checkInputs = [ openssh pytestCheckHook ];

    preCheck = ''
      export PYSISRC=${pysisrc}
      export PATH=$PATH:${binSearchPath}
      export OMPI_MCA_rmaps_base_oversubscribe=1
    '';

    pytestFlagsArray = if fullTest
      then [ "-v tests" ]
      else [ "-v --pyargs pysisyphus.tests"]
    ;

    postInstall = ''
      mkdir -p $out/share/pysisyphus
      cp ${pysisrc} $out/share/pysisyphus/pysisrc
      for exe in $out/bin/*; do
        wrapProgram $exe \
          ${if binSearchPath == "" then "" else "--prefix PATH : ${binSearchPath}"} \
          --set-default PYSISRC $out/share/pysisyphus/pysisrc \
          --set SCRATCH "./"
      done
    '';

    passthru = { inherit
      enableXtb
      enableJmol
      enableMultiwfn
      enableOpenmolcas
      enablePsi4
      enableWfoverlap
      enableNwchem
      enableOrca
      enableTurbomole
      enableGaussian
      enableCfour
      enableMolpro
      enableGamess
      ;
    };

    meta = with lib; {
      description = "Python suite for optimization of stationary points on ground- and excited states PES and determination of reaction paths";
      homepage = "https://github.com/eljost/pysisyphus";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [ maintainers.sheepforce ];
    };
  }
