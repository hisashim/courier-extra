#!/usr/bin/make -f

## variables

# metadata

PRODUCT = courier-extra
VERSION = $(shell cat VERSION)
PACKAGE = $(shell [ -f debian/changelog ] && \
                  head -n 1 debian/changelog | cut -d' ' -f 1)
DEBREV  = $(shell [ -f debian/changelog ] && \
                  head -n 1 debian/changelog \
                  | cut -d' ' -f 2 | sed 's/(\(.*\)-\(.*\))/\2/')

# programs

TEX     = tex -interaction batchmode
LATEX   = latex
DVITOPDF= dvipdfmx
MAP     = courier-extra
ifeq ("$(MAP)x","x")
  DVITOPDFFLAGS =
  LABEL         = $(TESTNAME)
else
  DVITOPDFFLAGS = -f $(MAP)
  LABEL         = $(TESTNAME)-$(MAP)
endif
TAR_XVCS= tar --exclude=".svn" --exclude=".git" --exclude=".hg"
DEBUILDOPTS=
PBUILDER = cowbuilder
PBOPTS   = --hookdir=pbuilder-hooks \
           --bindmounts "/var/cache/pbuilder/result"

# files and directories

DESTDIR =
TEXMFROOT = /usr/share/texlive
TEXMFDIST_OLD = /usr/share/texmf-texlive
TEXMFDIST = $(firstword $(wildcard $(TEXMFROOT)/texmf-dist $(TEXMFDIST_OLD)))
MAPDIRS = $(TEXMFDIST)/fonts/map/dvipdfmx

# Berry naming scheme
# (http://www.tex.ac.uk/cgi-bin/texfaq2html?label=fontname)
#   pcr    Adobe Courier
#   r|b    r:Regular, b:Bold
#   [o]    o:Oblique
#   8t|8c  8t:T1, 8c:TS1
#   [n]    n:Narrow, c:Condensed
FONTS   = \
        pcrr8t  pcrrc8t pcrro8t pcrr8tn pcrrc8tn        pcrro8tn        \
        pcrb8t  pcrbc8t pcrbo8t pcrb8tn pcrbc8tn        pcrbo8tn        \
        pcrr8c          pcrro8c pcrr8cn                 pcrro8cn        \
        pcrb8c          pcrbo8c pcrb8cn                 pcrbo8cn

SRC     = *.afm

TESTDOC = nfssfont
TESTPDFS= $(foreach f,$(FONTS),$(f)-$(LABEL).pdf)
TESTNAME= bigtest

DIST    = Makefile VERSION README.md ChangeLog devutils/ \
          courier-extra-driver.tex courier-extra-map.tex \
          courier-extra.sty courier-extra-test.tex \
          courier-extra.map courier-extra-fcr.map \
          courier-extra-pcr.map courier-extra-ucr.map \
          fcrbo8a.t1asm.patch fcrro8a.t1asm.patch \
          fcrb8a.t1asm.patch fcrr8a.t1asm.patch

RELEASE = $(PRODUCT)-$(VERSION)

DEB     = $(PACKAGE)_$(VERSION)-$(DEBREV)
DEBORIG = $(PACKAGE)_$(VERSION).orig

## targets

all: $(DIST) fontinst fcrpfb

.PHONY: all install uninstall fontinst fcrpfb test search \
	dist deb pbuilder-build pbuilder-login pbuilder-test debuild debuild-clean \
	mostlyclean clean maintainer-clean
.SECONDARY:

# installation

install: fontinst fcrpfb
	mkdir -p $(DESTDIR)$(TEXMFDIST)/fonts/tfm/public/courier-extra \
	         $(DESTDIR)$(TEXMFDIST)/fonts/vf/public/courier-extra \
	         $(DESTDIR)$(TEXMFDIST)/fonts/type1/public/courier-extra \
	         $(DESTDIR)$(TEXMFDIST)/tex/latex/courier-extra
	cp -r *.tfm $(DESTDIR)$(TEXMFDIST)/fonts/tfm/public/courier-extra
	cp -r *.vf  $(DESTDIR)$(TEXMFDIST)/fonts/vf/public/courier-extra
	cp -r fcr*.pfb $(DESTDIR)$(TEXMFDIST)/fonts/type1/public/courier-extra
	for d in $(MAPDIRS); do \
	  mkdir -p $(DESTDIR)$$d; \
	  cp *.map $(DESTDIR)$$d; \
	done
	cp -r *.fd  $(DESTDIR)$(TEXMFDIST)/tex/latex/courier-extra
	cp -r *.sty $(DESTDIR)$(TEXMFDIST)/tex/latex/courier-extra
	if [ -d $(DESTDIR)/usr/share/doc ]; then \
	  mkdir -p $(DESTDIR)/usr/share/doc/$(PRODUCT); \
	  cp README.md ChangeLog $(DESTDIR)/usr/share/doc/$(PRODUCT); \
	fi

uninstall:
	rm -fr $(DESTDIR)$(TEXMFDIST)/fonts/tfm/public/courier-extra \
	       $(DESTDIR)$(TEXMFDIST)/fonts/vf/public/courier-extra \
	       $(DESTDIR)$(TEXMFDIST)/fonts/type1/public/courier-extra \
	       $(DESTDIR)$(TEXMFDIST)/tex/latex/courier-extra
	for d in $(MAPDIRS); do \
	  if [ -d $(DESTDIR)$$d ]; then \
	    rm -f $(DESTDIR)$$d/$(PRODUCT)*.map; \
	  fi; \
	done
	rm -fr $(DESTDIR)/usr/share/doc/$(PRODUCT)

# generation

fontinst: courier-extra-driver.tex
	cp -r $(TEXMFDIST)/fonts/afm/adobe/courier/*.afm ./
	cp -r $(TEXMFDIST)/fonts/afm/adobe/symbol/*.afm ./
	$(TEX) $<
	$(TEX) courier-extra-map.tex
	rm -f *.afm
	for f in *.pl  ; do pltotf $$f; done
	for f in *.vpl ; do vptovf $$f; done

fcrpfb: fcrr8a.t1 fcrb8a.t1 fcrro8a.t1 fcrbo8a.t1
	cp fcrr8a.t1 fcrr8a.pfb
	cp fcrb8a.t1 fcrb8a.pfb
	cp fcrro8a.t1 fcrro8a.pfb
	cp fcrbo8a.t1 fcrbo8a.pfb

%.vf: %.vpl
	vptovf $< $@

%.tfm: %.pl
	pltotf $< $@

fcr%.t1asm: pcr%.t1asm fcr%.t1asm.patch
	cp $< $@
	patch $@ < $@.patch

%.t1: %.t1asm
	t1asm --output $@ $<

%.t1asm: %.pfb
	t1disasm --output $@ $<

pcr%.afm: $(TEXMFDIST)/fonts/afm/adobe/courier/pcr%.afm
	cp $< $@

pcr%.pfb: $(TEXMFDIST)/fonts/type1/adobe/courier/pcr%.pfb
	cp $< $@

ucr%.afm: $(TEXMFDIST)/fonts/afm/urw/courier/ucr%.afm
	cp $< $@

ucr%.pfb: $(TEXMFDIST)/fonts/type1/urw/courier/ucr%.pfb
	cp $< $@

# testing

test: fcrpfb $(TESTPDFS) courier-extra-test.pdf

%-$(LABEL).pdf: %-$(TESTDOC).pdf
	cp $< $@

%-testfont.dvi: %-testfont.tex
	$(TEX) $<

%-nfssfont.dvi: %-nfssfont.tex
	$(LATEX) $<

%-fontchart.dvi: %-fontchart.tex
	$(TEX) $<

%-testfont.tex: $(TEXMFDIST)/tex/plain/base/testfont.tex
	@sed 's/\(\\ifx\\noinit!\\else\\init\\fi\)/%% overwriting init\n% \1/' < $< > $@
	@/bin/echo '\def\init{\def\fontname{$(*)}\startfont' >> $@
	@/bin/echo '  \$(TESTNAME)}' >> $@
	@/bin/echo '\init\bye' >> $@
	# -diff -u $< $@

%-nfssfont.tex: $(TEXMFDIST)/tex/latex/base/nfssfont.tex
	@sed 's/\(\\ifx\\noinit!\\else\\init\\fi\)/%% overwriting init\n% \1/' < $< \
	| sed 's/\(\\endinput\)/% \1/' \
	| sed 's/\( \\typein\[\\currfontname\]%\)/% \1/' \
	| sed 's/\(   {Input external font name, e.g., cmr10^^J%\)/% \1/' \
	| sed 's/\(    (or <enter> for NFSS classification of font):}%\)/% \1/' \
	> $@
	@/bin/echo '\def\currfontname{$(*)}' >> $@
	@/bin/echo '\init\$(TESTNAME)\bye' >> $@
	@/bin/echo '\endinput' >> $@
	# -diff -u $< $@

%-fontchart.tex: $(TEXMFDIST)/tex/plain/base/fontchart.tex
	@sed 's/\(\\read-1 to \\fontname\)/% \1\n\\def\\fontname{$(*)\\relax}/'< $< \
	> $@
	# -diff -u $< $@

%.pdf:
%.pdf: %.dvi
	$(DVITOPDF) $(DVITOPDFFLAGS) -o $@ $<

%.dvi:
%.dvi: %.tex
	$(LATEX) $<

search:
	-for f in $(FONTS) ; \
	do \
	echo -n "$${f}.vf:      " ; kpsewhich $${f}.vf ; \
	echo -n "$${f}.tfm:     " ; kpsewhich $${f}.tfm ; \
	done

# source package

dist: $(RELEASE).tar.gz

$(RELEASE): $(DIST)
	mkdir -p $@
	($(TAR_XVCS) -cf - $(DIST)) | (cd $@ && tar xpf -)

ChangeLog:
	devutils/vcslog.sh > $@

%.tar.gz: %
	tar cfz $@ $<

# debian package

deb: pbuilder-build
	cp /var/cache/pbuilder/result/$(DEB).diff.gz ./
	cp /var/cache/pbuilder/result/$(DEB).dsc ./
	cp /var/cache/pbuilder/result/$(DEB)_all.deb ./
	cp /var/cache/pbuilder/result/$(DEBORIG).tar.gz ./

pbuilder-build: $(DEB).dsc
	sudo $(PBUILDER) --build $< -- $(PBOPTS)

pbuilder-login:
	sudo $(PBUILDER) --login $(PBOPTS)

pbuilder-test: $(DEB)_all.deb
	sudo $(PBUILDER) --execute $(PBOPTS) -- pbuilder-hooks/test.sh \
	$(PACKAGE) $(VERSION) $(DEBREV)
	cp /var/cache/pbuilder/result/$(DEB)-test.tar.gz ./

$(DEB).dsc: debuild

debuild: $(RELEASE) $(DEBORIG).tar.gz
	($(TAR_XVCS) -cf - debian) | (cd $(RELEASE) && tar xpf -)
	(cd $(RELEASE) && debuild $(DEBUILDOPTS); cd -)

$(DEBORIG).tar.gz: $(RELEASE).tar.gz
	cp -a $< $@

debuild-clean:
	rm -fr $(DEBORIG)
	rm -f $(DEB)_*.build $(DEB)_*.changes
	rm -fr debian/$(PRODUCT)
	rm -f $(DEB).dsc $(DEBORIG).tar.gz $(DEB).diff.gz $(DEB)_*.deb

# utilities

mostlyclean:	
	rm -f *.fd *.vpl *.mtx *.pl *.log *.aux *.dvi *.t1asm *.t1
	rm -f *-$(TESTDOC).*
	rm -f pcr*.pfb
	rm -fr $(RELEASE)

clean: mostlyclean
	rm -f *.afm *.vf *.tfm *.pdf *.pfb
	rm -f courier-extra-dvipdfm.map
	rm -f courier-extra-dvips.map
	rm -f courier-extra-rec.tex
	rm -f $(RELEASE).tar.gz

maintainer-clean: clean debuild-clean
	rm -f ChangeLog
