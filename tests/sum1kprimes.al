sum = 0
num = 2
count = 0

for() {
/*
	isprime = true
	math.sqrt( sqrnum, "${num}" )

	for( x, 2, "${sqrnum}" ) {
		math.mod( tmp, "${num}", "${x}" )
		if( "${tmp}" == 0 ) {
			isprime = false
			brkloop()
		}
	}
*/
	math.isprime( isprime, "${num}" )

	if( "${isprime}" == true ) {
		#print( "${num} is prime, adding it...\n" )
		math.add( sum, "${sum}", "${num}" )
		math.inc( count )
	} else {
		#print( "${num} is not prime\n" )
	}
	math.inc( num )
	if( "${count}" == 1000 ) {
		brkloop()
	}
}

print( "Sum of first 1000 prime numbers is: ${sum}\n" )