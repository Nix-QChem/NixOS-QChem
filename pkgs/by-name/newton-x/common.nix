{ fetchFromGitLab }:

rec {
  version = "26a";

  src = fetchFromGitLab {
    owner = "light-and-molecules";
    repo = "newton-x-package";
    rev = "dfe5405eb06a345d2d99684e3c4a80b6f1c1a348";
    hash = "sha256-1DQlVggU5UgTNbxFx3mwvkw8nmjIKYM43FrWlMzjOWQ=";
    fetchSubmodules = true;
  };
}
