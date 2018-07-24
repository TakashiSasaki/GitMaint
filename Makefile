.PHONY: check gitGc 

.DELETE_ON_ERROR: gitStatusDirty.dirs

.INTERMEDIATE: temp

check: gitFsckError.txt
	@echo Showing gitFsckError.txt ..
	@cat $<
	@echo Done.

clean:
	rm -rf find.txt du.txt dirs.txt files.txt gitDir.txt gitFile.txt

find.txt:
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	find $(GITMAINT) -print0 | xargs -0 ls -d --file-type |sort >$@
endif

du.dirs: all.dirs
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	 du $(GITMAINT) | sed -r -n -e 's/^[0-9]+[\t ]+//p' | sort >$@
	 diff $< $@
endif

all.dirs: find.txt
	cat $< | sed -n 's/\/$$//p' | sort >$@

all.files: find.txt
	cat $< | sed -n '/[^/]$$/p' | sort >$@

dotGitDir.dirs: all.dirs
	cat $< | sed -n 's/\/.git$$//p' | sort >$@

dotGitFile.dirs: all.files
	cat $< | sed -n 's/\/.git$$//p' | sort >$@

gitFsck.txt: dotGitDir.dirs
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git fsck --no-progress --full --strict 2>&1' _ >$@

gitFsckError.txt: gitFsck.txt
	cat $< | sed -n -e '/^\//h' -e '/^[^\/]/{g;p}' | uniq >$@
	cat $@

gitGc: gitFsckError.txt
	cat $< | xargs -n 1 sh -c 'set -e; cd "$$1" ; pwd; git gc --prune=now' _

gitUnbornBranch.txt: gitFsck.txt
	cat $< | sed -n -e '/^\//h' -e '/HEAD points to an unborn branch/{g;p}' >$@

dotGitmodules.files: all.files
	cat $< | sed -n -e '/\/.gitmodules$$/p' >$@

dotGitmodules.dirs: all.files
	cat $< | sed -n -e 's/\/.gitmodules$$//p' >$@

dotGit.dirs: dotGitDir.dirs dotGitFile.dirs
	cat $^ | sort | uniq >$@

gitStatusDirty.dirs: gitStatus.txt
	cat $^ | sed -n -e "/^\//{h}" -e "/^ /{g;p}" >$@
	@cat $@
	@test `wc -l $@ | awk '{print $$1}'` -ne 0

gitStatus.txt: dotGit.dirs
	cat $^ | xargs -n 1 sh -c 'set -e; cd "$$1"; pwd; git status --porcelain' _>$@

