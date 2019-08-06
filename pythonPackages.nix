{ python } :

python.override {
  packageOverrides = self: super: {
    pyscf = super.callPackage ./pyscf { };
  };
}
