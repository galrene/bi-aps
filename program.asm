.data
.align 2

array:
.word 2, 3, 8, 5, 7

.text

#----------------------------------------------------------------
main:
	addi a1, zero, 5 # arr_size
	la a2, array # arr begin
	jal ra, prime

inf_loop:
	jal, zero, inf_loop
# a2 = number address
isPrime:
	# i upper bound = a4
	lw a4, 0(a2) # int a4 = *a2
	addi t1, zero, 2 # i = 2
	loop_isPrime:
		beq a4, t1, end_prime # if i == num

		rem t2, a4, t1 # t2 = a4 % t1
		beq zero, t2, end_not_prime # if ( a4 % t1 == 0 ) return 0

		addi t1, t1, 1
		jal, zero, loop_isPrime

	end_prime:
		addi t1, zero, 1
		sw t1, 0(a2) # *a2 = 1
		jalr zero, ra, 0
	end_not_prime:
		sw zero, 0(a2) # *a2 = 0
		jalr zero, ra, 0
#----------------------------------------------------------------
# a1 = arr size
# a2 = arr begin
prime:
	add s0, zero, ra # save ret address
	add t6, zero, a1 # i upper bound = arrSize
	addi t5, zero, 0 # i = 0
	loop_primes:
		beq t5, t6, end_primes_check # i == arrSize
	# {
		add a3, zero, a2
		jal ra, isPrime
	# }
		addi a2, a2, 4 # arr_ptr++
		addi t5, t5, 1 # i++
		jal, zero, loop_primes
	end_primes_check:
		jalr zero, s0, 0 # ret
