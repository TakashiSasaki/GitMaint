.PHONY: clean all

all: clean sub2

.git:
	git init
	cat $@/config

sub1: .git
	mkdir $@
	cd $@; git init
	cd $@; cat .git/config
	echo $@>$@/$@.txt
	cd $@; git add --all
	cd $@; git commit -m $@

sub2: sub1 .git
	git submodule add --name $@nickname ./sub1 $@
	cat $@/.git
	cat .gitmodules
	cat .git/config

clean:
	-find . -regex ".+[.]git$$" -exec rm -rf {} \;
	rm -rf sub1 sub2
	rm -f .gitmodules

