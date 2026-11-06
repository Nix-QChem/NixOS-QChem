{
  lib,
  buildPythonPackage,
  fetchFromGitLab,
  psi4,
  numpy,
  scipy,
  h5py,
  packaging,
  pyyaml,
}:

buildPythonPackage (finalAttrs: {
  pname = "psi4-cbo";
  version = "1.2.0";

  pyproject = true;

  src = fetchFromGitLab {
    domain = "gitlab.fysik.su.se";
    owner = "thomas.schnappinger";
    repo = "psi4-cbo";
    tag = "v${finalAttrs.version}";
    hash = "sha256-t/sbHErj8xsn6fGmU+wkl/oHkrhAfdH+Y48JYaxnsNw=";
  };

  dependencies = [
    psi4
    numpy
    scipy
    h5py
    packaging
    pyyaml
  ];

  meta = {
    description = "Extension to Psi4 to cavity Born-Oppenheimer calculations";
    homepage = "https://gitlab.fysik.su.se/thomas.schnappinger/psi4-cbo/";
    maintainers = [ lib.maintainers.markuskowa ];
    license = lib.licenses.gpl3Only;
  };
})
