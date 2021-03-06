project( "Alacrity-Lang" ) {
	version( 0.1 )
	language( cpp, 17 )
	license( bsd3 )
	author( Electrux, "ElectruxRedsworth@gmail.com" )
}

if( "${PREFIX}" == "" ) {
	PREFIX = "%{pwd}"
}

builds.add_flags( "-march=native", "-O2", "-flto", "-fPIC", "-pedantic", "-Wall", "-Wextra", "-Wno-unused-parameter", "-DBUILD_PREFIX_DIR=${PREFIX}" )

use_lib( sfml_audio )
use_lib( sfml_network )
use_lib( pthread )
use_lib( dl )

builds( bin ) {
	sources( "src/(.*)\.cpp", "-src/Modules/(.*)\.cpp" )
	build( al, "src/main.cpp" )
}

builds( lib, dynamic ) {
	sources( "src/(.*)\.cpp", "-src/main.cpp", "-src/Modules/(.*)\.cpp" )
	build( core, "src/Modules/core.cpp" )
	build( time, "src/Modules/time.cpp" )
	build( os, "src/Modules/os.cpp" )
	build( string, "src/Modules/string.cpp" )
	build( math, "src/Modules/math.cpp" )
	build( list, "src/Modules/list.cpp" )
	build( audio, "src/Modules/audio.cpp" )
	build( net, "src/Modules/net.cpp" )
	build( project, "src/Modules/project.cpp" )
	build( builds, "src/Modules/builds.cpp, src/Modules/builds/c_cxx.cpp" )
}

if( "${ARGC}" > 0 && "${ARG_0}" == "install" ) {
	if( "${IS_ROOT}" == "true" || "${OS}" == OS_OSX ) {
		install( "buildfiles/al", "${PREFIX}/bin/" )
		install( "buildfiles/lib*.so", "${PREFIX}/share/allang_libs/" )
		install( "build_libs/*", "${PREFIX}/share/allang_tests/" )
	} else {
		print( "{r}Run as root to install the built files{0}\n" )
	}
}
