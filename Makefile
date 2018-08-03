include MakefileLib/env.mk
include MakefileLib/diff.mk
include MakefileLib/color.mk

define enter
$(if $(filter %.out,$@),$(call cyan,"=> $@"))
$(if $(filter %.files,$@),$(call green,"=> $@"))
$(if $(filter %.dirs,$@),$(call yellow,"=> $@"))
$(if $(suffix $@),,$(call magenta,"=> $@"))
endef

define leave
$(if $(filter %.out,$@),$(call cyan,"<= $@"))
$(if $(filter %.files,$@),$(call green,"<= $@"))
$(if $(filter %.dirs,$@),$(call yellow,"<= $@"))
$(if $(suffix $@),,$(call magenta,"<= $@"))
endef

.PHONY: \
	git-fsck \
	git-gc \
	gitCleanWouldRemove \
	gitFsckUnborn\
	gitGc \
	gitStatusDirty \
	help \
	notInSubmoduleTree \
	onlyInSubmoduleTree \
	testUndefinedMacro \

.DELETE_ON_ERROR: gitStatusDirty.dirs git-fsck.error

.INTERMEDIATE: temp


URI=file://$(USER)@$(HOST)$(ROOT)
URIMD5=$(shell echo $(URI)| md5sum | sed -n -r 's/(^[0-9a-fA-F]+).*$$/\1/p')
OUTDIR=$(shell echo $(URIMD5) | sed -n -r 's/(^[0-9a-fA-F]{5}).*$$/out-\1/p')

help:
	@echo -- Example targets:
	@echo make git-fsck
	@echo make git-gc

vpath %.out $(OUTDIR)
vpath %.dirs $(OUTDIR)
vpath %.files $(OUTDIR)
vpath %.error $(OUTDIR)
#GPATH=$(OUTDIR)

clean:
	$(call enter)
	rm -rf ./out-?????/
	rm -rf *.dirs *.files *.out
	$(call leave)

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

diff-find-du: du.out find.dirs
	diff $(OUTDIR)/$(word 1, $(notdir $^)) $(OUTDIR)/$(word 2, $(notdir $^))

working.dirs: find.dirs
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n 's/\/.git$$//p' \
		| sort \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

module.dirs: find.files
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n 's/\/.git$$//p' \
		| sort \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

repo.dirs: working.dirs module.dirs
	$(call enter)
	cat $(OUTDIR)/$(word 1,$(notdir $^)) $(OUTDIR)/$(word 2,$(notdir $^)) \
		| sort \
		| uniq \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

git-fsck.out: repo.dirs
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| xargs -n 1 sh -c \
			'set -e; cd "$$1" ; pwd; git fsck --no-progress --full --strict 2>&1' _ \
		> $(OUTDIR)/$@ 
	@wc -l $(OUTDIR)/$@
	@test -s $(OUTDIR)/$@ 
	$(call leave)

git-fsck.error: git-fsck.out
	$(call enter)
	@cat $(OUTDIR)/$(notdir $<) \
		| sed -n -e '/^\//h' -e '/^[^\/]/{x;p;x;p}' \
		>$(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	#@test ! -s $(OUTDIR)/$@ 
	if [ ! -s $(OUTDIR)/$@ ]; then rm $(OUTDIR)/$@; fi
	$(call leave)

git-fsck::
	-rm $(OUTDIR)/git-fsck.out
	-rm $(OUTDIR)/git-fsck.error

git-fsck:: git-fsck.error
	@cat $(OUTDIR)/$(notdir $<) 
	@wc -l $(OUTDIR)/$@
	@test ! -s $(OUTDIR)/$@ 

git-gc.out: repo.dirs
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| xargs -n 1 sh -c \
			'set -e; cd "$$1" ; pwd; git gc --prune=now' _  \
		2>&1| tee $(OUTDIR)/$@
	$(call leave)

git-gc.error: git-gc.out
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n -e '/^\//h' -e '/fatal/{x;p;x;p}' \
		2>&1 | tee $(OUTDIR)/$@
	@wc -l $(OUTDIR)/$@
	@test ! -s $(OUTDIR)/$@ 
	@if [ -s $(OUTDIR)/$@ ]; then rm $(OUTDIR)/$@; fi
	$(call leave)

git-gc::
	-rm $(OUTDIR)/git-gc.error
	-rm $(OUTDIR)/git-gc.out

git-gc:: git-gc.error
	@cat $(OUTDIR)/$(notdir $<) 
	@-wc -l $(OUTDIR)/$@
	@test ! -s $(OUTDIR)/$@ 

gitmodules.files: find.files
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n -e '/.*\/\.gitmodules$$/p' \
		>$(OUTDIR)/$@
	#cat $(OUTDIR)/$@
	$(call leave)

gitconfig.files: find.files
	$(call enter)
	cat $(OUTDIR)/$(notdir $<) \
		| sed -n -e '/.*\/\.git\/config$$/p' \
		>$(OUTDIR)/$@
	#cat $(OUTDIR)/$@
	$(call leave)

gitStatusDirty: gitStatus.out
	$(call enter)
	@cat $^ | sed -n -e "/^\//{h}" -e "/^ /{x;p;x;p}" 
	$(call leave)

$(OUTDIR)/gitStatus.out: repo.dirs
	$(call enter)
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git status --porcelain' _>$@
	$(call leave)

$(OUTDIR)/gitClean.out: repo.dirs
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

$(OUTDIR)/onlyInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs repo.dirs
	$(call enter)
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^))  >$@
	$(call leave)

onlyInSubmoduleTree: onlyInSubmoduleTree.dirs
	$(call enter)
	@cat $<
	$(call leave)

$(OUTDIR)/notInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs repo.dirs
	$(call enter)
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^))  >$@
	$(call leave)

notInSubmoduleTree: notInSubmoduleTree.dirs
	$(call enter)
	@cat $<
	$(call leave)

######################   PLAYGROUND   ########################

