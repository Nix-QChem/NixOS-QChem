{ stdenv, lib, pkgs, buildInputs, name, tests } :

let
  setupTests = builtins.concatStringsSep "\n" (map (t : ''
      run-${t.name} () {
      logFile=`basename ${t.input}`.log
      result=`basename ${t.input}`.res

      echo -ne "Running test ${t.name}:\t\t\t\t\t"
      SECONDS=0

      ${pkgs.writeScript "testDriver.sh" t.driver} ${t.input} > $logFile

      echo "Runtime: $SECONDS s" >> $result

      echo "Result:" >> $result
      grep '${t.result}' ${if t.outfile != null then t.outfile else "$logFile"} >> $result
      if [ ! $? ]; then
        echo "[Test failed!]"
      else
        echo "[OK]"
      fi

      cp $logFile $out
      cp $result $out
      ${if t.outfile != null then "cp " + t.outfile  + " $out" else ""}
      }
      '') tests);

   runTests = builtins.concatStringsSep "\n" (map (t : ''
      run-${t.name}
     '') tests);


in stdenv.mkDerivation {

  inherit name buildInputs;

  phases = [ "setupPhase" "runPhase" ];

  setupPhase = setupTests;

  runPhase = ''
    mkdir -p $out

    echo
    echo "Running all tests:"
    ${runTests}

    results=`find $out/ -name "*.res"  -type f`

    echo -n "" > $out/summary
    for i in $results; do
      t=`sed -n 's/Runtime: //p' $i`
      echo -e "`basename $i`:\t\t\t$t" >> $out/summary
    done

    echo
    echo "Summary timings:"
    cat $out/summary
    echo
  '';

  shellHook = ''
    setupPhase () { ${setupTests}   }
    runPhase () { ${runTests}  }
    export out=./
  '';
}

