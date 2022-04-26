.name "zork"
and r1, %0, r1
.comment "I'M ALIIIIVE"

l2:		sti r1, %:live, %1


live:	live %1
		zjmp %:live
