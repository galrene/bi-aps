# .data
# .align 2
# size:
# .word 0
# .word 7
# array:
# .word 0xC
# .word 2, 3, 8, 5, 7, -1, 13
# .text

#----------------------------------------------------------------
# Check if s0-numbers at address stored at a0 are prime, set the respective values to 1 (prime) or 0 (not prime)
# s0 = arr size
# a0 = arr begin
main:
	lw s0, 0x4 # arr_size
	lw a0, 0x8 # arr begin address
	blt s0, x0, end
	
	addi s1, zero, 0 # s1 == i = 0
	loop_primes:
		beq s1, s0, end # i == arrSize
	# {
		jal ra, prime
	# }
		addi a0, a0, 4 # arr_ptr++
		addi s1, s1, 1 # i++
		jal, zero, loop_primes
#----------------------------------------------------------------
end:
	jal, zero, end
#----------------------------------------------------------------
# Check if number at address a0 is prime, set a0 to 1 (prime) or 0 (not prime)
# a0 = number address
prime:
	# i upper bound = t0
	lw t0, 0(a0) # int t0 = *a0
	addi t1, zero, 2 # i = 2
	loop_prime:
		beq t0, t1, end_prime # if i == num
		
		blt t0, zero, end_not_prime # num < 0 -> not prime

		rem t2, t0, t1 # t2 = t0 % t1
		beq zero, t2, end_not_prime # if ( t0 % t1 == 0 ) return 0

		addi t1, t1, 1
		jal, zero, loop_prime

	end_prime:
		addi t1, zero, 1
		sw t1, 0(a0) # *a0 = 1
		jalr zero, ra, 0
	end_not_prime:
		sw zero, 0(a0) # *a0 = 0
		jalr zero, ra, 0
