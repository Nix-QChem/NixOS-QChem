{ stdenv, lib, pkgs, buildInputs, name, tests } :

let
  setupTests = builtins.concatStringsSep "\n" (map (t : ''
      run-${t.name} () {
      logFile=`basename ${t.input}`.log
      result=`basename ${t.input}`.res

      mkdir -p ${t.name}.dir
      cd ${t.name}.dir

      echo "Running test ${t.name}"
      SECONDS=0

      ${pkgs.writeScript "testDriver.sh" t.driver} ${t.input} > $logFile

      echo "Runtime: $SECONDS s" >> $result

      echo "Result:" >> $result
      ${if t.result != null then
        "grep -e '" + t.result + "' " + (if t.outfile != null then t.outfile else "$logFile") + " >> $result\n"
      else
        ""
      }

      ${if t.error != null then
        "grep -e '" + t.error + "' " 
        + (if t.outfile != null then t.outfile else "$logFile") + " >> $result "
        + "&& false"
      else
        ""
      }

      cp $logFile $out
      cp $result $out
      ${if t.outfile != null then "cp " + t.outfile  + " $out" else ""}
   
      cd ..   
      rm -r ${t.name}.dir
      }
      '') tests);

   runTests = builtins.concatStringsSep "\n" (map (t : ''
      run-${t.name}
     '') tests);


in stdenv.mkDerivation {
  
  name = "test-" + name;

  inherit buildInputs;

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
      printf '%s\033[40G%s\n' `basename $i` "$t" >> $out/summary
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

