all:
	rm -rf out/*
	cp -rf src/* out
	livescript -c `tree -if out | grep -e '.*\.ls$$'`
	rm -rf `tree -if out | grep -e '.*\.ls$$'`
