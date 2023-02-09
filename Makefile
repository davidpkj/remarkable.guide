DIST=$(CURDIR)/dist
SRC=$(CURDIR)/src
IMAGES=$(CURDIR)/images
VENV=$(CURDIR)/.venv
BUILD=$(CURDIR)/.build

texFiles := $(wildcard $(IMAGES)/*.svg.tex)
imageFiles := $(texFiles:$(IMAGES)/%.svg.tex=$(SRC)/_static/images/%.svg)

.PHONY: all prod images dev dev-images clean

all: prod

$(VENV)/bin/activate:
	@echo "Setting up development virtual env in .venv"
	python -m venv .venv; \
	. .venv/bin/activate; \
	python -m pip install -r requirements.txt

$(SRC)/_static/images/%.svg: $(IMAGES)/%.svg.tex
	mkdir -p $(BUILD)/images
	cd $(IMAGES) && pdflatex \
	    -shell-escape \
	    -halt-on-error \
	    -file-line-error \
	    -interaction nonstopmode \
	    -output-directory=../../.build/images \
	    $*.svg.tex
	pdf2svg $(BUILD)/images/$*.svg.pdf $(SRC)/_static/images/$*.svg

$(SRC)/_static/images/favicon.png: $(SRC)/_static/images/favicon.svg
	rsvg-convert -h 180 $(SRC)/_static/images/favicon.svg -o $(SRC)/_static/images/favicon.png

images: $(imageFiles) $(SRC)/_static/images/favicon.png

$(DIST): $(VENV)/bin/activate images
	. $(VENV)/bin/activate; \
	    sphinx-build -a -n -E -b html $(SRC) $(DIST)
	# Clean unused files inherited from default theme
	rm -rf $(DIST)/.doctrees \
	    $(DIST)/.buildinfo \
	    $(DIST)/genindex.html \
	    $(DIST)/objects.inv \
	    $(DIST)/search.html \
	    $(DIST)/searchindex.js \
	    $(DIST)/_sources \
	    $(DIST)/_static/basic.css \
	    $(DIST)/_static/doctools.js \
	    $(DIST)/_static/documentation_options.js \
	    $(DIST)/_static/file.png \
	    $(DIST)/_static/jquery-3.5.1.js \
	    $(DIST)/_static/jquery.js \
	    $(DIST)/_static/language_data.js \
	    $(DIST)/_static/minus.png \
	    $(DIST)/_static/plus.png \
	    $(DIST)/_static/pygments.css \
	    $(DIST)/_static/searchtools.js \
	    $(DIST)/_static/underscore-1.13.1.js \
	    $(DIST)/_static/underscore.js \

prod: $(DIST)

dev: $(VENV)/bin/activate $(SRC)/_static/images/favicon.png $(imageFiles)
	. $(VENV)/bin/activate; \
	    sphinx-autobuild -a $(SRC) $(DIST)

dev-images:
	while inotifywait -e close_write $(IMAGES)/*.tex;do \
	    rm -f $(imageFiles); \
	    $(MAKE) $(imageFiles); \
	done

clean:
	rm -rf $(DIST) $(VENV) $(BUILD)
	rm -f $(SRC)/_static/images/*.png $(SRC)/_static/images/*.svg
