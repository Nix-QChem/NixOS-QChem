{ stdenv, lib, requireFile, autoPatchelfHook, tcsh, perl, openssh
, writeScript, runtimeShell, hostname
, minorVersion ? 1
} :

assert
  lib.asserts.assertMsg
  (builtins.elem minorVersion [ 1 2 3 4 ])
  "Unsupported version of Q-Chem";

let
  url = "https://www.q-chem.com/install/#linux";
  qchemSrc-5_1 = requireFile {
    inherit url;
    name = "qc5${builtins.toString minorVersion}.tar";
    sha256 = "71b0d7fd4f6b47a090e25267c53fb38f5dbc50a8d159f2e8669ecba8f88f5d96";
  };
  qchemSrc-5_2 = requireFile {
    inherit url;
    name = "qc5${builtins.toString minorVersion}.tar";
    sha256 = "cf513b8215369d9e904f7f22bca5f8d43a39b3fd166c2e4ddf5f67965b50a6fa";
  };
  qchemSrc-5_3 = requireFile {
    inherit url;
    name = "qc5${builtins.toString minorVersion}.tar";
    sha256 = "5e616542e3bd20ef299fed97ef8f8ab30c3fa264cdc0c8fe900bfa30d975c3d8";
  };
  qchemSrc-5_4 = requireFile {
    inherit url;
    name = "qc5${builtins.toString minorVersion}.tar";
    sha256 = "5f62677c17fc62f6da2eb6d3f43efcc9569e5feea9313c870729c562aa3e41a9";
  };

  # Runs the installer script and prepares valid installation in the store.
  # License will be missing after the installation, thus this preliminary
  # version will not work, yet. Use the activation script to obtain a license.
  qchemInit = stdenv.mkDerivation rec {
    pname = "Q-Chem";
    version = "5.${builtins.toString minorVersion}";

    src =
      if minorVersion == 1 then qchemSrc-5_1
      else if minorVersion == 2 then qchemSrc-5_2
      else if minorVersion == 3 then qchemSrc-5_3
      else if minorVersion == 4 then qchemSrc-5_4
      else "";

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];
    runtimeDependencies = buildInputs;
    propagatedBuildInputs = [ tcsh perl openssh ];

    sourceRoot = if minorVersion == 4 then "qc54_distrib" else ".";

    postPatch = ''
      patchShebangs ./qcinstall.sh
    '';

    dontConfigure = true;
    dontBuild = true;

    # Run the interactive configuration script.
    # It will prepare a file to be sent to license@q-chem.com,
    # but the HostIds will be missing, as get_hostid has not been fixed yet.
    installPhase =
      let installAnswers = lib.strings.concatStringsSep "\n" ([
            "$out"                     # Installation directory
            "1"                        # Flavour to install. 1 -> SMP parallel, > 1 different MPI and CUDA flavours
            ""                         # Skip a count down
            "/tmp"                     # Default scratch directory. ignored when finishing the derivation in the second step
            "2000"                     # Default memory for Q-Chem processes in MiB. ignored when finishing derivation in the second step
            "n"                        # Don't view license
            "y"                        # Agree to license
            ""                         # Skip countdown
            "3000"                     # Order number, that works for all Q-Chem versions 5.{1..4}
            "someone@example.com"      # Fake mail adress substituted later. Needs to be a well formed, though
            "y"                        # Confirm that the answers are "correct". Of course they are not, but the activation script solves this later
          ] ++ lib.optional (minorVersion >= 2) "1" # Use a license file instead of setting up a separate license server
          );
      in ''
        ./qcinstall.sh << EOF
        ${installAnswers}
        EOF
      '';

    autoPatchelfIgnoreMissingDeps = true;
    postFixup = ''
      # Patch shebangs of perl and csh scripts
      find -name "*.pl" -exec sed -i "s!/usr/bin/perl!${perl}/bin/perl" {} \;
      find -name "*.csh" -exec sed -i "s!/bin/csh!${tcsh}/bin/tcsh" {} \;
    '';

    meta = with lib; {
      description = "General purpose quantum chemistry program with Gaussian basis sets";
      homepage = "https://q-chem.com/";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      maintainers = [ maintainers.sheepforce ];
    };
  };

  getLicense = writeScript "q-chem_prep-license" ''
    #! ${runtimeShell}
    set -e

    if [[ -z "$QCHEM_NODES" || -z "$QCHEM_MAIL" || -z "$QCHEM_ORDNUM" ]]
      then
        echo "Set the \$QCHEM_NODES variable to a list of hostnames, which should be part of the Q-Chem license."
        echo "Set \$QCHEM_MAIL to your mail account, associated with the Q-Chem license."
        echo "Set \$QCHEM_ORDNUM to your order number for your Q-Chem license."
        echo "The script will use MPI to obtain the required information from all Nodes."
      else
        # Obtain the Q-Chem information on all nodes.
        # Dials in via ssh and executes the get_hostid command
        HOSTINFO=$(for N in $QCHEM_NODES; do
          if [[ "$N" = "$(${hostname}/bin/hostname)" || "$N" == "localhost" || "$N" == "127.0.0.1" ]]
            then ${qchemInit}/bin/get_hostid
            else ssh $N ${qchemInit}/bin/get_hostid
          fi
        done)

        # Update the license file
        HEAD=$(head -n -2 ${qchemInit}/license.data)
        FOOT="#end_sid"
        printf "$HEAD\n  $HOSTINFO\n  $FOOT" > license.data
        sed -i "s/someone@example.com/$QCHEM_MAIL/g" license.data
        sed -i "s/3000/$QCHEM_ORDNUM/g" license.data
        echo "Send ./license.data to license@q-chem.com"
    fi
  '';

in { inherit qchemInit getLicense; }
