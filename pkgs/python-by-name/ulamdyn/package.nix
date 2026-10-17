{ buildPythonPackage
, lib
, newtonxSrc
, setuptools
, numpy
, scipy
, h5py
, pandas
, scikit-learn
, rmsd
, joblib
, ase
, tqdm
, dscribe
, tslearn
, pythonRelaxDepsHook
}:

buildPythonPackage (finalAttrs: {
  pname = "ulamdyn";
  version = "1.1.1";
  pyproject = true;

  src = newtonxSrc;

  sourceRoot = "source/Ulamdyn";

  build-system = [ setuptools ];

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  dependencies = [
    numpy
    scipy
    h5py
    pandas
    scikit-learn
    rmsd
    joblib
    ase
    tqdm
    dscribe
    tslearn
  ];

  pythonRelaxDeps = [
    "numpy"
    "scipy"
    "scikit-learn"
    "black"
    "setuptools"
    "ase"
    "tqdm"
    "sparse"
    "dscribe"
    "matplotlib"
    "pandas"
  ];

  pythonRemoveDeps = [ "black" ];

  pythonImportsCheck = [ "ulamdyn" ];

  meta = with lib; {
    description = "Unsupervised learning analysis for molecular dynamics data (Newton-X package component)";
    homepage = "https://gitlab.com/light-and-molecules/ulamdyn";
    license = licenses.lgpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
})
