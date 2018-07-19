.PHONY: clean 

.git:
	git init
	cat $@/config

sub1: .git
	mkdir $@
	echo $@>$@/$@.txt
	cd git; git init
	cd git; cat .git/config


clean:
	-find . -regex ".+[.]git$$" -exec rm -rf {} \;
	rm -rf sub1

