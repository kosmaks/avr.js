coffee:
	rm -rf out/*
	cp -rf src/* out
	coffee -c `tree -if out | grep -e '.*\.coffee$$'`
	rm -rf `tree -if out | grep -e '.*\.coffee$$'`
