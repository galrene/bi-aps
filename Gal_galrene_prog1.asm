#  .data
#  .align 2
#  size:
#  .word 0
#  .word 5
#  array:
#  .word 0xC
#  .word 2, 3, 8, 5, 7
#  .text

#----------------------------------------------------------------
# Check if a1-numbers at address a2 are prime, set the respective values to 1 (prime) or 0 (not prime)
# a1 = arr size
# a2 = arr begin
main:
	lw a1, 0x4 # arr_size
	lw a0, 0x8 # arr begin address
	blt a1, x0, end
	
	add t6, zero, a1 # i upper bound = arrSize
	addi t5, zero, 0 # i = 0
	loop_primes:
		beq t5, t6, end # i == arrSize
	# {
		jal ra, prime
	# }
		addi a0, a0, 4 # arr_ptr++
		addi t5, t5, 1 # i++
		jal, zero, loop_primes
#----------------------------------------------------------------
end:
	jal, zero, end
#----------------------------------------------------------------
# Check if number at address a0 is prime, set a0 to 1 (prime) or 0 (not prime)
# a0 = number address
prime:
	# i upper bound = a4
	lw a4, 0(a0) # int a4 = *a0
	addi t1, zero, 2 # i = 2
	loop_prime:
		beq a4, t1, end_prime # if i == num
		
		blt a4, zero, end_not_prime # num < 0 -> not prime

		rem t2, a4, t1 # t2 = a4 % t1
		beq zero, t2, end_not_prime # if ( a4 % t1 == 0 ) return 0

		addi t1, t1, 1
		jal, zero, loop_prime

	end_prime:
		addi t1, zero, 1
		sw t1, 0(a0) # *a0 = 1
		jalr zero, ra, 0
	end_not_prime:
		sw zero, 0(a0) # *a0 = 0
		jalr zero, ra, 0
