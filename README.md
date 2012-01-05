courier-extra
=============

courier-extra is a set of virtual font files to use Courier with extra
series and shapes in LaTeX.

Features
--------

  * New font "fcr": pcr with ucr-like easy-to-distinguish opening quote
    symbols (`).

  * New LaTeX font definition "pcre": pcr with extra series and shapes,
    e.g. pcr(r|b)[co]8tn.
    - extra series: condensed (narrow) (85%)
    - extra shapes: slant (oblique) and small caps

Requirements
------------

  * Adobe Courier (pcr*.afm, pcr*.pfb)
  * Adobe Symbol (psy*.afm)
  * t1utils (t1disasm, t1asm)
  * patchutils (patch)

Installation
------------

    $ make
    $ sudo make install
    $ sudo mktexlsr

Testing
-------

    $ cp /usr/share/doc/vfdata-courier-extra/examples/courier-extra-test.tex ./
    $ latex courier-extra-test.tex
    $ dvipdfmx -f courier-extra.map -o courier-extra-test.pdf courier-extra-test.dvi
    $ dvipdfmx -f courier-extra-ucr.map -o courier-extra-test-ucr.pdf courier-extra-test.dvi
    $ dvipdfmx -f courier-extra-pcr.map -o courier-extra-test-pcr.pdf courier-extra-test.dvi
    $ dvipdfmx -f courier-extra-fcr.map -o courier-extra-test-fcr.pdf courier-extra-test.dvi
    $ xpdf courier-extra-test.pdf &
    $ rm courier-extra-test-*.{tex,aux,log,dvi,pdf}

Usage
-----

    $ $EDITOR foo.tex
    cat foo.tex
    \documentclass{article}
    \usepackage{courier-extra}% \\ttdefault is set to pcre
    \begin{document}
    \ttfamily                   Courier extra    \\
    \mdseries                   medium           \\
    \fontseries{mc}\selectfont  medium condensed \\
    \bfseries                   bold             \\
    \fontseries{bc}\selectfont  bold condensed   \\
    \upshape\selectfont         normal           \\
    \itshape\selectfont         italic           \\
    \slshape\selectfont         slant            \\
    \scshape\selectfont         smallcaps
    \end{document}
    $ latex foo.tex
    $ dvipdfmx -f courier-extra.map -o foo.pdf foo.dvi
    $ dvipdfmx -f courier-extra-fcr.map -o foo-fcr.pdf foo.dvi

Font Maps
---------

Four DVIPDFMx maps are included:

  * courier-extra.map:     same as courier-extra-ucr.map
  * courier-extra-ucr.map: maps pcr to ucr (URW Courier)
  * courier-extra-pcr.map: maps pcr to pcr (Adobe Courier)
  * courier-extra-fcr.map: maps pcr to fcr (Modified Courier)

Notes
-----

Font characteristics:

  * URW Courier (ucr): slightly thinner than Adobe Courier. Some glyphs
    are different than Adobe's, e.g. in @, #, `, etc. URW Courier seems
    to be the default in LaTeX.

  * Adobe Courier (pcr): slightly bolder than URW Courier. Some glyphs
    are different than URW's, e.g. in @, #, `, etc.

  * Modified Courier (fcr): Based on Adobe Courier, but with URW-like
    quoteleft (`) and quotedblleft (``).

Known Problems:

  * Print at least one character in medium series prior to other series
    and shapes. Otherwise, extra series and shapes may not print
    correctly. Possible workaround is like:

        {\\ttfamily
         \fontseries{m}\selectfont  medium
         \fontseries{mc}\selectfont medium condensed
         \fontseries{bc}\selectfont bold condensed}
        ...

    Any advise to fix it is highly appreciated.
