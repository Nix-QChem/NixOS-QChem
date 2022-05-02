{ stdenv, lib, fetchFromGitHub, autoreconfHook, ucx
, enableCuda ? false
, cudatoolkit
, enableAvx ? stdenv.hostPlatform.avxSupport
, enableSse41 ? stdenv.hostPlatform.sse4_1Support
, enableSse42 ? stdenv.hostPlatform.sse4_2Support
} :

stdenv.mkDerivation rec {
  pname = "ucc";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "openucx";
    repo = "ucc";
    rev = "v${version}";
    sha256 = "006nv1b1gwh8hpjmghirsx8138800z4ll7xwwz89ddaazmq2mdx8";
  };

  postPatch = ''
    substituteInPlace src/components/mc/cuda/kernel/Makefile.am \
      --replace "/bin/bash" "${stdenv.shell}"
  '';

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs = [ ucx ]
    ++ lib.optional enableCuda cudatoolkit;

  configureFlags = [ ]
   ++ lib.optional enableSse41 "--with-sse41"
   ++ lib.optional enableSse42 "--with-sse42"
   ++ lib.optional enableAvx "--with-avx"
   ++ lib.optional enableCuda "--with-cuda=${cudatoolkit}";

  meta = with lib; {
    description = "Collective communication operations API";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}
