.PHONY: \
	check \
	gitCleanWouldRemove \
	git-fsck-all\
	gitFsckUnborn\
	gitGc \
	gitStatusDirty \
	help \
	notInSubmoduleTree \
	onlyInSubmoduleTree \
	testColors \
	testUndefinedMacro \

.DELETE_ON_ERROR: gitStatusDirty.dirs

.INTERMEDIATE: temp

include env.mk

URI=file://$(USER)@$(HOST)$(ROOT)
URIMD5=$(shell echo $(URI)| md5sum | sed -n -r 's/(^[0-9a-fA-F]+).*$$/\1/p')
OUTDIR=$(shell echo $(URIMD5) | sed -n -r 's/(^[0-9a-fA-F]{5}).*$$/out-\1/p')

help:
	@echo ROOT=$(ROOT)
	@echo USER=$(USER)
	@echo HOST=$(HOST)
	@echo URI=$(URI)
	@echo URIMD5=$(URIMD5)
	@echo OUTDIR=$(OUTDIR)
	@echo MAKE_HOST=$(MAKE_HOST)

vpath %.out $(OUTDIR)
vpath %.dirs $(OUTDIR)
vpath %.files $(OUTDIR)
#GPATH=$(OUTDIR)

include diff.mk

include color.mk

clean:
	$(call enter)
	rm -rf ./out-?????/
	rm -rf *.dirs *.files *.out
	$(call leave)

check: clean gitFsckError

find.out:
	$(call enter)
	@-mkdir $(OUTDIR)
	find $(ROOT) -print0 \
		| xargs -0 ls -d --file-type \
		| sort \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

find.files: find.out
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n '/[^/]$$/p'\
		| sort \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

find.dirs: find.out
	$(call enter)
	@-mkdir $(OUTDIR)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n 's/\/$$//p' \
		| sort \
		> $(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

du.out:
	$(call enter)
	@-mkdir $(OUTDIR)
	du $(ROOT) \
		| sed -r -n -e 's/^[0-9]+[\t ]+//p' \
		| sort \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

check-find-du: du.out find.dirs
	diff $(OUTDIR)/$(word 1, $(notdir $^)) $(OUTDIR)/$(word 2, $(notdir $^))

#$(OUTDIR)/dotGitDir.dirs: find.dirs
working.dirs: find.dirs
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n 's/\/.git$$//p' \
		| sort \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

$(OUTDIR)/dotGitFile.dirs: find.files
	$(call enter)
	cat $< | sed -n 's/\/.git$$//p' | sort >$@
	$(call leave)

$(OUTDIR)/gitFsck.out: dotGit.dirs
	$(call enter)
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git fsck --no-progress --full --strict 2>&1' _ | tee $@
	$(call leave)

git-fsck-all: gitFsck.out
	$(call enter)
	@cat $< | sed -n -e '/^\//h' -e '/^[^\/]/{x;p;x;p}'
	$(call leave)

gitGc: gitFsckError.dirs
	$(call enter)
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git gc --prune=now' _
	$(call leave)

gitFsckUnborn: gitFsck.out
	$(call enter)
	cat $< | sed -n -e '/^\//h' -e '/HEAD points to an unborn branch/{x;p;x;p}' 
	$(call leave)

$(OUTDIR)/dotGitmodules.files: find.files
	$(call enter)
	cat $< | sed -n -e '/\/.gitmodules$$/p' >$@
	$(call leave)

$(OUTDIR)/dotGitmodules.dirs: find.files
	$(call enter)
	cat $< | sed -n -e 's/\/.gitmodules$$//p' >$@
	$(call leave)

dotGit.dirs: working.dirs dotGitFile.dirs
	$(call enter)
	cat $(OUTDIR)/$(word 1,$(notdir $^)) $(OUTDIR)/$(word 2,$(notdir $^)) \
		| sort \
		| uniq \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

gitStatusDirty: gitStatus.out
	$(call enter)
	@cat $^ | sed -n -e "/^\//{h}" -e "/^ /{x;p;x;p}" 
	$(call leave)

$(OUTDIR)/gitStatus.out: dotGit.dirs
	$(call enter)
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git status --porcelain' _>$@
	$(call leave)

$(OUTDIR)/gitClean.out: dotGit.dirs
	$(call enter)
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git clean -ndx' _ >$@
	$(call leave)

gitCleanWouldRemove: gitClean.out
	$(call enter)
	@cat $^ | sed -n -e '/^Would skip repository/d' -e '/^\//{h}' -e '/^Would remove/{x;p;x;p}'
	$(call leave)

$(OUTDIR)/gitSubmoduleForEachPwd.out: $(OUTDIR)
	$(call enter)
	(cd $(ROOT); git submodule foreach --recursive pwd) >$@
	$(call leave)

$(OUTDIR)/gitSubmoduleForEachPwd.dirs: gitSubmoduleForEachPwd.out
	$(call enter)
	cat $< | sed -n -e '/^\//p' | sort | uniq >$@
	$(call leave)

gitSubmoduleForEachPwd: gitSubmoduleForEachPwd.dirs
	$(call enter)
	@cat $<
	$(call leave)

$(OUTDIR)/onlyInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs dotGit.dirs
	$(call enter)
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^))  >$@
	$(call leave)

onlyInSubmoduleTree: onlyInSubmoduleTree.dirs
	$(call enter)
	@cat $<
	$(call leave)

$(OUTDIR)/notInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs dotGit.dirs
	$(call enter)
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^))  >$@
	$(call leave)

notInSubmoduleTree: notInSubmoduleTree.dirs
	$(call enter)
	@cat $<
	$(call leave)

######################    PLAYGROUND   ########################

testDiffOnlyInRight: left.txt right.txt
	$(call enter)
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^)) 
	$(call leave)

testDiffOnlyInLeft: left.txt right.txt
	$(call enter)
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^)) 
	$(call leave)
	
testDiffInBoth: left.txt right.txt
	$(call enter)
	$(call diffInBoth, $(word 1,$^), $(word 2,$^)) 
	$(call leave)

testColors:
	$(call enter)
	$(call red,red)
	$(call blue,blue)
	$(call green,green)
	$(call white,white)
	$(call magenta,magenta)
	$(call cyan,cyan)
	$(call yellow,yellow)
	$(call leave)

