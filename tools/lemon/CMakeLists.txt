cmake_minimum_required( VERSION 3.16 )

if( NOT CMAKE_CROSSCOMPILING )
	set( CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -D_DEBUG" )

	add_executable( lemon lemon.c )
	# lemon.c predates C23: its empty-parens declarations conflict with the
	# definitions under GCC 16's default -std=gnu23.
	set_property( TARGET lemon PROPERTY C_STANDARD 17 )
	set( CROSS_EXPORTS ${CROSS_EXPORTS} lemon PARENT_SCOPE )

	# Lemon wants lempar.c in its directory
	add_custom_command( TARGET lemon
		POST_BUILD
		COMMAND echo $<TARGET_FILE_DIR:lemon>
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/lempar.c $<TARGET_FILE_DIR:lemon> )	
endif()
