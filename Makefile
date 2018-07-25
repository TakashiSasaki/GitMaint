.PHONY: check gitGc gitCleanWouldRemove gitStatusDirty onlyInSubmoduleTree notInSubmoduleTree gitFsckError gitFsckUnborn\
	testUndefinedMacro

.DELETE_ON_ERROR: gitStatusDirty.dirs

.INTERMEDIATE: temp

define GITMAINT_DIR
$(if $(GITMAINT),$(GITMAINT),$(error GITMAINT is empty or not set.))
endef

GITMAINT_MD5=$(shell echo $(GITMAINT)| md5sum | sed -n -r 's/(^[0-9a-fA-F]+).*$$/\1/p')

OUTDIR=$(shell echo $(GITMAINT_MD5) | sed -n -r 's/(^[0-9a-fA-F]{5}).*$$/out-\1/p')


vpath %.out $(OUTDIR)
vpath %.dirs $(OUTDIR)
vpath %.files $(OUTDIR)

define diffOnlyInLeft
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^-(.*)$$/\1/p'
endef

define diffOnlyInRight
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^\+(.*)$$/\1/p'
endef

define diffInBoth
	diff -U10 $1 $2 | tail -n +3 | sed -n -r 's/^ (.*)$$/\1/p'
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

define enter
$(if $(filter %.out,$@),$(call cyan,"=> $@"))
$(if $(filter %.files,$@),$(call green,"=> $@"))
$(if $(filter %.dirs,$@),$(call yellow,"=> $@"))
$(if $(suffix $@),,$(call magenta,"=> $@"))
endef

define leave
@#$(if $(filter %.out,$@),$(call cyan,"<= $@"))
@#$(if $(filter %.files,$@),$(call green,"<= $@"))
@#$(if $(filter %.dirs,$@),$(call yellow,"<= $@"))
@#$(if $(suffix $@),,$(call magenta,"<= $@"))
endef


check: clean gitFsckError

$(OUTDIR):
	$(call enter)
	mkdir $(OUTDIR)
	$(call leave)

clean:
	$(call enter)
	rm -rf ./out-?????/
	rm -rf *.dirs *.files *.out
	$(call leave)

$(OUTDIR)/find.out: $(OUTDIR)
	$(call enter)
	find $(call GITMAINT_DIR) -print0 \
		| xargs -0 ls -d --file-type |sort >$@
	$(call leave)

$(OUTDIR)/du.dirs: all.dirs 
	$(call enter)
	du $(call GITMAINT_DIR) \
	 | sed -r -n -e 's/^[0-9]+[\t ]+//p' | sort >$@
	diff $< $@
	$(call leave)

$(OUTDIR)/all.dirs: find.out
	$(call enter)
	cat $< | sed -n 's/\/$$//p' | sort >$@
	$(call leave)

$(OUTDIR)/all.files: find.out
	$(call enter)
	cat $< | sed -n '/[^/]$$/p' | sort >$@
	$(call leave)

$(OUTDIR)/dotGitDir.dirs: all.dirs
	$(call enter)
	cat $< | sed -n 's/\/.git$$//p' | sort >$@
	$(call leave)

$(OUTDIR)/dotGitFile.dirs: all.files
	$(call enter)
	cat $< | sed -n 's/\/.git$$//p' | sort >$@
	$(call leave)

$(OUTDIR)/gitFsck.out: dotGit.dirs
	$(call enter)
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git fsck --no-progress --full --strict 2>&1' _ >$@
	$(call leave)

gitFsckError: gitFsck.out
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

$(OUTDIR)/dotGitmodules.files: all.files
	$(call enter)
	cat $< | sed -n -e '/\/.gitmodules$$/p' >$@
	$(call leave)

$(OUTDIR)/dotGitmodules.dirs: all.files
	$(call enter)
	cat $< | sed -n -e 's/\/.gitmodules$$//p' >$@
	$(call leave)

$(OUTDIR)/dotGit.dirs: dotGitDir.dirs dotGitFile.dirs
	$(call enter)
	cat $^ | sort | uniq >$@
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
	(cd $(call GITMAINT_DIR); git submodule foreach --recursive pwd) >$@
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
	$(call diffOnlyInLeft, $(word 1,$^), $(word 2,$^))  >$@

onlyInSubmoduleTree: onlyInSubmoduleTree.dirs
	$(call enter)
	@cat $<
	$(call leave)

$(OUTDIR)/notInSubmoduleTree.dirs: gitSubmoduleForEachPwd.dirs dotGit.dirs
	$(call diffOnlyInRight, $(word 1,$^), $(word 2,$^))  >$@

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
