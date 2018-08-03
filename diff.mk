test-diff-mk: left.txt right.txt
	$(call enter)
	$(call yellow, left.txt)
	@cat left.txt
	$(call yellow, right.txt)
	@cat right.txt
	$(call yellow,showing lines only in right.txt)
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^)) 
	$(call yellow,showing lines only in left.txt)
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^)) 
	$(call yellow,showing lines in both left.txt and right.txt)
	$(call diffInBoth, $(word 1,$^), $(word 2,$^)) 
	$(call leave)

include color.mk

left.txt:
	echo -e one\nthree\nleft\nfour\nfive\nsix\nnine\nten >$@

right.txt:
	echo -e zero\none\nthree\nfour\nright\nfive\neight\nnine\nten >$@

define diffOnlyInLeft
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^-(.*)$$/\1/p'
endef

define diffOnlyInRight
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^\+(.*)$$/\1/p'
endef

define diffInBoth
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^ (.*)$$/\1/p'
endef

