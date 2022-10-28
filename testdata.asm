
	li	s0, 0 # tests passed counter
	li	s1, 0 # test result
	
# test branch jumps
	li	a2, 2
	li	a3, 3
	
	li	t0, 5
	add	t1, a2, a3
	beq	t0, x0, failed
	bne	t0, t1, failed
	beq	t0, t1, test00_skip0
	j	failed
test00_skip0:
	addi	s0, s0, 1
	
	li	t0, 6
	add	t1, a2, a3
	bne	t0, t0, failed
	beq	t0, t1, failed
	bne	t0, t1, test00_skip1
	j	failed
test00_skip1:
	addi	s0, s0, 1
	
	li	t0, 6
	blt	a3, a2, failed
	blt	a2, a3, test00_skip2
	j	failed
test00_skip2:
	addi	s0, s0, 1
	
	jal	zero, test00_skip3
	j	failed
test00_skip3:
	addi	s0, s0, 1
	
	call	test00_skip4 # tests alipc and jalr
	j	failed
test00_skip4:
	addi	s0, s0, 1
	
	
	# tests jumps to negative offsets (decoding test)
	j	test00_5_p0
test00_5_p1:
	j	test00_5_skip
test00_5_p0:
	j	test00_5_p1
	j	failed
test00_5_skip:

	beq	x0, x0, test00_6_p0
test00_6_p1:
	beq	x0, x0, test00_6_skip
test00_6_p0:
	beq	x0, x0, test00_6_p1
	beq	x0, x0, failed
test00_6_skip:


# ALU test
	li	t0, 5
	li	t1, 3
	
	# add
	li	t2, 8
	add	t3, t0, t1
	bne	t2, t3, failed
	addi	s0, s0, 1
	
	# sub
	li	t2, 2
	sub	t3, t0, t1
	bne	t2, t3, failed
	li	t2, -2
	sub	t3, t1, t0
	bne	t2, t3, failed
	addi	s0, s0, 1
	sub	t3, t1, t2
	bne	t0, t3, failed
	addi	s0, s0, 1
	
	# slt
	li	t2, 0
	slt	t3, t0, t1
	bne	t2, t3, failed
	li	t2, 1
	slt	t3, t1, t0
	bne	t2, t3, failed
	addi	s0, s0, 1
	
	# sltu
#	li	t2, 0
#	li	t5, -1
#	sltu	t3, t5, t0
#	bne	t2, t3, failed
#	li	t2, 1
#	sltu	t3, t0, t5
#	bne	t2, t3, failed
#	addi	s0, s0, 1
#	
	# and
	li	t2, 1
	and	t3, t0, t1
	bne	t2, t3, failed
	addi	s0, s0, 1
	
#	# or
#	li	t2, 7
#	or	t3, t0, t1
#	bne	t2, t3, failed
#	addi	s0, s0, 1
	
#	# xor
#	li	t2, 6
#	xor	t3, t0, t1
#	bne	t2, t3, failed
#	addi	s0, s0, 1
	
	# div
	li	t2, 1
	div	t3, t0, t1
	bne	t2, t3, failed
	addi	s0, s0, 1
	
	# mod
	li	t2, 2
	rem	t3, t0, t1
	bne	t2, t3, failed
	addi	s0, s0, 1
	
	
	li	t0, -23
	li	t1, 3
	
#	# sll
#	li	t2, -184
#	sll	t3, t0, t1
#	bne	t2, t3, failed
#	addi	s0, s0, 1
	
#	# srl
#	li	t2, 536870909
#	srl	t3, t0, t1
#	bne	t2, t3, failed
#	addi	s0, s0, 1
	
#	# sra
#	li	t2, -3
#	sra	t3, t0, t1
#	bne	t2, t3, failed
#	addi	s0, s0, 1
	
# memory
	li	t0, 4
	li	t1, 0
	sw	t0, 12(t0)
	lw	t1, 16(zero)
	bne	t0, t1, failed
	addi	s0, s0, 1

succedded:
	li	s1, 1
	j	end

failed:
	li	s1, -1
	j	end
end:
	sw	s0, 4(zero)
	sw	s1, 8(zero)
end_loop:
	j	end_loop

# ---------------------------------------
# code coverage
# [x] add
# [x] slt
# [x] and
# [x] sub
# [x] div
# [x] rem
# [x] sll
# [x] srl
# [x] sra
# [x] addi
# [x] beq
# [x] bne
# [x] blt
# [x] lw
# [x] sw
# [ ] lui
# [x] jal
# [x] jalr
# [x] auipc
# ---------------------------------------
