.PHONY: check gitGc gitCleanWouldRemove gitStatusDirty onlyInSubmoduleTree notInSubmoduleTree gitFsckError gitFsckUnborn

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

define blue
	@bash -c 'echo -e "\e[34m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define magenta
	@bash -c 'echo -e "\e[35m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define cyan
	@bash -c 'echo -e "\e[36m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define white
	@bash -c 'echo -e "\e[37m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

check: clean gitFsckError

$(OUTDIR):
	$(call green,$@)
	mkdir $(OUTDIR)

clean:
	$(call green,$@)
	rm -rf ./out-?????/
	rm -rf *.dirs *.files *.out

$(OUTDIR)/find.out: $(OUTDIR)
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	$(call green,$@)
	find $(GITMAINT) -print0 | xargs -0 ls -d --file-type |sort >$@
endif

$(OUTDIR)/du.dirs: all.dirs
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	$(call green,$@)
	 du $(GITMAINT) | sed -r -n -e 's/^[0-9]+[\t ]+//p' | sort >$@
	 diff $< $@
endif

$(OUTDIR)/all.dirs: find.out
	$(call green,$@)
	cat $< | sed -n 's/\/$$//p' | sort >$@

$(OUTDIR)/all.files: find.out
	$(call green,$@)
	cat $< | sed -n '/[^/]$$/p' | sort >$@

$(OUTDIR)/dotGitDir.dirs: all.dirs
	$(call green,$@)
	cat $< | sed -n 's/\/.git$$//p' | sort >$@

$(OUTDIR)/dotGitFile.dirs: all.files
	$(call green,$@)
	cat $< | sed -n 's/\/.git$$//p' | sort >$@

$(OUTDIR)/gitFsck.out: dotGit.dirs
	$(call green,$@)
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git fsck --no-progress --full --strict 2>&1' _ >$@

gitFsckError: gitFsck.out
	$(call cyan,$@)
	@cat $< | sed -n -e '/^\//h' -e '/^[^\/]/{x;p;x;p}'

gitGc: gitFsckError.dirs
	$(call green,$@)
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git gc --prune=now' _

gitFsckUnborn: gitFsck.out
	$(call cyan,$@)
	cat $< | sed -n -e '/^\//h' -e '/HEAD points to an unborn branch/{x;p;x;p}' 

$(OUTDIR)/dotGitmodules.files: all.files
	$(call green,$@)
	cat $< | sed -n -e '/\/.gitmodules$$/p' >$@

$(OUTDIR)/dotGitmodules.dirs: all.files
	$(call green,$@)
	cat $< | sed -n -e 's/\/.gitmodules$$//p' >$@

$(OUTDIR)/dotGit.dirs: dotGitDir.dirs dotGitFile.dirs
	$(call green,$@)
	cat $^ | sort | uniq >$@

gitStatusDirty: gitStatus.out
	$(call cyan,$@)
	@cat $^ | sed -n -e "/^\//{h}" -e "/^ /{x;p;x;p}" 

$(OUTDIR)/gitStatus.out: dotGit.dirs
	$(call green,$@)
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git status --porcelain' _>$@

$(OUTDIR)/gitClean.out: dotGit.dirs
	$(call green,$@)
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git clean -ndx' _ >$@

gitCleanWouldRemove: gitClean.out
	$(call cyan,$@)
	@cat $^ | sed -n -e '/^Would skip repository/d' -e '/^\//{h}' -e '/^Would remove/{x;p;x;p}'

$(OUTDIR)/gitSubmoduleForEachPwd.out: $(OUTDIR)
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	$(call green,$@)
	(cd "$(GITMAINT)"; git submodule foreach --recursive pwd) >$@
endif

$(OUTDIR)/gitSubmoduleForEachPwd.dirs: gitSubmoduleForEachPwd.out
	$(call green,$@)
	cat $< | sed -n -e '/^\//p' | sort | uniq >$@

gitSubmoduleForEachPwd: gitSubmoduleForEachPwd.dirs
	$(call cyan,$@)
	@cat $<

$(OUTDIR)/onlyInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs dotGit.dirs
	$(call green,$@)
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^))  >$@

onlyInSubmoduleTree: onlyInSubmoduleTree.dirs
	$(call cyan,$@)
	@cat $<

$(OUTDIR)/notInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs dotGit.dirs
	$(call green,$@)
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^))  >$@

notInSubmoduleTree: notInSubmoduleTree.dirs
	$(call cyan,$@)
	@cat $<

######################    PLAYGROUND   ########################

testDiffOnlyInRight: left.txt right.txt
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^)) 

testDiffOnlyInLeft: left.txt right.txt
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^)) 
	
testDiffInBoth: left.txt right.txt
	$(call diffInBoth, $(word 1,$^), $(word 2,$^)) 

testUndefinedMacro:
	$(call undefinedMacro)

testColors:
	$(call red,red)
	$(call blue,blue)
	$(call green,green)
	$(call white,white)
	$(call magenta,magenta)
	$(call cyan,cyan)
	$(call yellow,yellow)

