.PHONY: check gitGc gitCleanWouldRemove gitStatusDirty onlyInSubmoduleTree notInSubmoduleTree gitFsckError gitFsckUnborn\
	testUndefinedMacro

.DELETE_ON_ERROR: gitStatusDirty.dirs

.INTERMEDIATE: temp

GITMAINT_MD5=$(shell echo $(GITMAINT)| md5sum | sed -n -r 's/(^[0-9a-fA-F]+).*$$/\1/p')

OUTDIR=$(shell echo $(GITMAINT_MD5) | sed -n -r 's/(^[0-9a-fA-F]{5}).*$$/out-\1/p')

vpath %.out $(OUTDIR)
vpath %.dirs $(OUTDIR)
vpath %.files $(OUTDIR)

define diffOnlyInLeft
	@diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^-(.*)$$/\1/p'
endef

define diffOnlyInRight
	@diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^\+(.*)$$/\1/p'
endef

define diffInBoth
	@diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^ (.*)$$/\1/p'
endef

define resetColor
	@bash -c 'echo -e "\e[m"'
endef

define black
	@bash -c 'echo -e "\e[30m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define red
	@bash -c 'echo -e "\e[31m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define green
	@bash -c 'echo -e "\e[32m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define yellow
	@bash -c 'echo -e "\e[33m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define enterYellow
	$(call yellow, "=> $@")
endef

define leaveYellow
	$(call yellow, "<= $@")
endef

define blue
	@bash -c 'echo -e "\e[34m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define magenta
	@bash -c 'echo -e "\e[35m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define cyan
	@bash -c 'echo -e "\e[36m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define enterCyan
	$(call cyan, "=> $@")
endef

define leaveCyan
	$(call cyan, "<= $@")
endef

define white
	@bash -c 'echo -e "\e[37m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

check: clean gitFsckError

$(OUTDIR):
	mkdir $(OUTDIR)

clean:
	rm -rf ./out-?????/
	rm -rf *.dirs *.files *.out

$(OUTDIR)/find.out: $(OUTDIR)
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	find $(GITMAINT) -print0 | xargs -0 ls -d --file-type |sort >$@
endif

$(OUTDIR)/du.dirs: all.dirs
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	 du $(GITMAINT) | sed -r -n -e 's/^[0-9]+[\t ]+//p' | sort >$@
	 diff $< $@
endif

$(OUTDIR)/all.dirs: find.out
	cat $< | sed -n 's/\/$$//p' | sort >$@

$(OUTDIR)/all.files: find.out
	cat $< | sed -n '/[^/]$$/p' | sort >$@

$(OUTDIR)/dotGitDir.dirs: all.dirs
	cat $< | sed -n 's/\/.git$$//p' | sort >$@

$(OUTDIR)/dotGitFile.dirs: all.files
	cat $< | sed -n 's/\/.git$$//p' | sort >$@

$(OUTDIR)/gitFsck.out: dotGit.dirs
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git fsck --no-progress --full --strict 2>&1' _ >$@

gitFsckError: gitFsck.out
	$(call enterCyan)
	@cat $< | sed -n -e '/^\//h' -e '/^[^\/]/{x;p;x;p}'
	$(call leaveCyan)

gitGc: gitFsckError.dirs
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git gc --prune=now' _

gitFsckUnborn: gitFsck.out
	$(call enterYellow)
	cat $< | sed -n -e '/^\//h' -e '/HEAD points to an unborn branch/{x;p;x;p}' 
	$(call leaveYellow)

$(OUTDIR)/dotGitmodules.files: all.files
	cat $< | sed -n -e '/\/.gitmodules$$/p' >$@

$(OUTDIR)/dotGitmodules.dirs: all.files
	cat $< | sed -n -e 's/\/.gitmodules$$//p' >$@

$(OUTDIR)/dotGit.dirs: dotGitDir.dirs dotGitFile.dirs
	cat $^ | sort | uniq >$@

gitStatusDirty: gitStatus.out
	$(call enterYellow)
	@cat $^ | sed -n -e "/^\//{h}" -e "/^ /{x;p;x;p}" 
	$(call leaveYellow)

$(OUTDIR)/gitStatus.out: dotGit.dirs
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git status --porcelain' _>$@

$(OUTDIR)/gitClean.out: dotGit.dirs
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git clean -ndx' _ >$@

gitCleanWouldRemove: gitClean.out
	$(call cyan,$@)
	@cat $^ | sed -n -e '/^Would skip repository/d' -e '/^\//{h}' -e '/^Would remove/{x;p;x;p}'

$(OUTDIR)/gitSubmoduleForEachPwd.out: $(OUTDIR)
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	(cd "$(GITMAINT)"; git submodule foreach --recursive pwd) >$@
endif

$(OUTDIR)/gitSubmoduleForEachPwd.dirs: gitSubmoduleForEachPwd.out
	cat $< | sed -n -e '/^\//p' | sort | uniq >$@

gitSubmoduleForEachPwd: gitSubmoduleForEachPwd.dirs
	$(call enterCyan)
	@cat $<
	$(call leaveCyan)

$(OUTDIR)/onlyInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs dotGit.dirs
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^))  >$@

onlyInSubmoduleTree: onlyInSubmoduleTree.dirs
	$(call enterCyan)
	@cat $<
	$(call leaveCyan)

$(OUTDIR)/notInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs dotGit.dirs
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^))  >$@

notInSubmoduleTree: notInSubmoduleTree.dirs
	$(call enterCyan)
	@cat $<
	$(call leaveCyan)

######################    PLAYGROUND   ########################

testDiffOnlyInRight: left.txt right.txt
	$(call enterYellow)
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^)) 
	$(call leaveYellow)

testDiffOnlyInLeft: left.txt right.txt
	$(call enterYellow)
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^)) 
	$(call leaveYellow)
	
testDiffInBoth: left.txt right.txt
	$(call enterYellow)
	$(call diffInBoth, $(word 1,$^), $(word 2,$^)) 
	$(call leaveYellow)

testColors:
	$(call red,red)
	$(call blue,blue)
	$(call green,green)
	$(call white,white)
	$(call magenta,magenta)
	$(call cyan,cyan)
	$(call yellow,yellow)

