define diffOnlyInLeft
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^-(.*)$$/\1/p'
endef

define diffOnlyInRight
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^\+(.*)$$/\1/p'
endef

define diffInBoth
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^ (.*)$$/\1/p'
endef


