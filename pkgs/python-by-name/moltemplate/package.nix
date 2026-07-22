{ buildPythonPackage, lib, makeWrapper, fetchFromGitHub, numpy, setuptools }:

buildPythonPackage rec {
  pname = "moltemplate";
  version = "2.22.4";

  src = fetchFromGitHub {
    owner = "jewettaij";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-YYgnswwwjKPr33UAZAVtiTj7ledwy8htlR7jknrjuSo=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ numpy ];

  doCheck = false; # There are no checks
  pythonImportsCheck = [ "moltemplate" ];

  # moltemplate.sh (and emoltemplate.sh, cleanup_moltemplate.sh) invoke the
  # *.py console_scripts via `python3 "<file>.py"`.  The default
  # wrapPythonPrograms replaces those .py files with bash wrappers (so they
  # find their python dependencies), which breaks this `python3 file.py`
  # invocation with a SyntaxError.  Instead, leave the .py files as proper
  # Python (they already carry a nix store python shebang) and only wrap the
  # shell entry points with the python interpreter on PATH.
  dontWrapPythonPrograms = true;
  postFixup = ''
    buildPythonPath "$out $pythonPath"
    for script in moltemplate.sh emoltemplate.sh cleanup_moltemplate.sh; do
      wrapProgram "$out/bin/$script" \
        --prefix PATH ':' "$program_PATH" \
        --prefix PYTHONPATH ':' "$program_PYTHONPATH"
    done
  '';

  meta = with lib; {
    homepage = "https://www.moltemplate.org/";
    description = "A general cross-platform tool for preparing simulations of molecules and complex molecular assemblies";
    license = licenses.mit;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "moltemplate.sh";
  };
}
