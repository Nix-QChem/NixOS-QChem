[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)
[![DOI:10.1002/qua.26872](http://img.shields.io/badge/DOI-10.1002/qua.26872-5075bf.svg)](https://doi.org/10.1002/qua.26872)

# NixOS-QChem
Nix expressions for HPC/Quantum chemistry software packages.

The goal of this project is to integrate software packages
into nixos to make it suitable for running it on a HPC cluster.
It provides popular quantum chemistry packages and performance optimization to upstream nixpkgs.

### Available Packages
A list packages can be found here: [Package list](./package_list.md)

### Publication
The design and packaging approach of the overlay are published here:
[M.Kowalewski, P. Seeber, Int. J. Quantum. Chem., e26872 (2022)](https://doi.org/10.1002/qua.26872)

## Usage

### Overlay
The repository comes as a nixpkgs overlay (see [Nixpkgs manual](https://nixos.org/nixpkgs/manual/#chap-overlays) for how to install an overlay).
The contents of the overlay will be placed in an attribute set under nixpkgs (default `qchem`). The original, but overridden nixpkgs will be placed in `qchem.pkgs`. This allows for composition of the overlay with different variants.

There is a branch (release-XX.XX) for every stable version of nixpkgs (nixos-XX.XX).

`examples/pinned-project-shell/shell.nix` and `examples/jupyter/shell.nix` also contain examples how to compose a package set and define an environment with packages from the overlay.

### Channel
Via `release.nix` a nix channels compatible nixexprs tarball can be generated:
`nix-build release.nix -A qchem.channel`
If you have set a different `cfg.prefix`/`NIXQC_PREFIX` adapt the expression to match the chosen subset name.


### NUR
The applications from the overlay are also available via [Nix User Repository (NUR)](https://github.com/nix-community/NUR) (qchem repo).
Access via e.g.: `nix-shell -p nur.repos.qchem.<package name>`.

### Binary cache
The latest builds for the master branch and stable version are stored on [Cachix](https://app.cachix.org/):
* Cache URL: https://nix-qchem.cachix.org
* Public key: nix-qchem.cachix.org-1:ZjRh1PosWRj7qf3eukj4IxjhyXx6ZwJbXvvFk3o3Eos=

If you are allowed to add binary substituters (as trusted user),
you may simply add it with `nix-shell -p cachix --run "cachix use nix-qchem"`.

## Configuration

The overlay can be configured either via an attribute set or via environment variables.
If no attribute set is given the configuration the environment variables are automatically
considered (impure).

### Special Installation Instructions

#### Q-Chem
The Q-Chem version `5.{1..4}` are packaged. Download the Linux binaries with all options enabled for your respective version at [https://www.q-chem.com/install/#linux](https://www.q-chem.com/install/#linux).
Q-Chem is evaluated in two steps to obtain a valid license, after the installer has run.

  1. Build the installer `nix-build -A qchem.q-chem-installer`.
     This will install Q-Chem into the store and prepare a preliminary `license.data` file, and prepare a script, that helps you to obtain the final `license.data`.
     The `qchem.q-chem-installer.getLicense` attribute (available as `./result/bin/q-chem_prep_license`) requires the following environment variables

     - `$QCHEM_NODES`: a space-separated list of nodes, for which a Q-Chem license should be obtained. All nodes must be reachable via MPI.
     - `$QCHEM_MAIL`: the e-mail address associated with the Q-Chem license. The license file will be sent to this address by Q-Chem.
     - `$QCHEM_ORDNUM:` the order number for Q-Chem.

     After these variables have been set, run `./result/bin/q-chem_prep_license`. You should now have `./license.data`. Send this file via mail to `license@q-chem.com`.

  2. After you have received your license file from `license@q-chem.com`, point `$NIXQC_LICQCHEM` or `licQChem` to this file.
     The `qchem.q-chem` attribute can be used normally, now; i.e. `nix-build -A qchem.q-chem`.


### Configuration via nixpkgs
Configuration options can be set directly via `config.qchem-config` alongside other nixpkgs config options.

* `allowEnv` : Allow to override the configuration from the environment (default false when `config.qchem-config` is used).
* `prefix`: The packages of the overlay will be placed in subset specified by `prefix` (default `qchem`).
* `srcurl`: URL for non-free packages. If set this will override the `requireFile` function of nixpkgs to pull all non-free packages from the specified URL
* `optpath`: Path to packages that reside outside the nix store. This is mainly relevant for Gaussian and Matlab.
* `licMolpro`: Molpro license token string required to run molpro.
* `optArch`: Set gcc compiler flags (`mtune` and `march`) to optimize for a specific architecture. Some upstream packages will be overridden to use make use of AVX (see `nixpkgs-opt.nix`). Note, that this also overrides the stdenv
* `useCuda`: Uses Cuda features in selected packages.
* `licQChem`: Path to a Q-Chem license file as obtained via mail.


### Configuration via environment variables
The overlay will check for environment variables to configure some features:

* `NIXQC_PREFIX`
* `NIXQC_SRCURL`
* `NIXQC_OPTPATH`
* `NIXQC_LICMOLPRO`
* `NIXQC_AVX`: see `optAVX`, setting this to 1 corresponds to `true`.
* `NIXQC_OPTARCH`
* `NIXQC_CUDA`: see `useCuda`, setting this to 1 corresponds to `true`.
* `NIXQC_LICQCHEM`: see `licQChem`
