.PHONY: checkTarget gitGc

clean:
	rm -rf find.txt du.txt dirs.txt files.txt gitDir.txt gitFile.txt

find.txt:
ifndef GITMAINT
	@echo GITMAINT is not set. ; exit 1
else
	find $(GITMAINT) -print0 | xargs -0 ls -d --file-type |sort >$@
endif

du.txt:
	 du | sed -r -n -e 's/^[0-9]+[\t ]+//p' | sort >$@

dirs.txt: find.txt
	cat find.txt | sed -n 's/\/$$//p' | sort >$@

files.txt: find.txt
	cat find.txt | sed -n '/[^/]$$/p' | sort >$@

gitDir.txt: du.txt dirs.txt
	diff du.txt dirs.txt
	cat dirs.txt | sed -n 's/\/.git$$//p' | sort >$@

gitFile.txt: files.txt
	cat $< | sed -n 's/\/.git$$//p' | sort >$@

gitFsck.txt: gitDir.txt
	cat $< | xargs -n 1 sh -c 'cd "$$1" ; pwd; git fsck --no-progress --full --strict 2>&1' _ >$@

gitFsckError.txt: gitFsck.txt
	cat $< | sed -n -e '/^\//h' -e '/^[^\/]/{g;p}' | uniq >$@

gitGc: gitFsckError.txt
	cat $< | xargs -n 1 sh -c 'cd "$$1" ; pwd; git gc --prune=now' _

gitUnbornBranch.txt: gitFsck.txt
	cat $< | sed -n -e '/^\//h' -e '/HEAD points to an unborn branch/{g;p}' >$@



