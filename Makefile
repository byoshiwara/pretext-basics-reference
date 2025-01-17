## ********************************************************************* ##
## Copyright 2018-2019                                                   ##
## Mitchel T. Keller                                                     ##
##                                                                       ##
## This file is part of The PreTeXt Basics Reference (The PBR).          ##
##                                                                       ##
## Permission is granted to copy, distribute and/or modify this          ##
## document under the terms of the GNU Free Documentation License,       ##
## Version 1.3 or any later version published by the Free Software       ##
## Foundation; with no Invariant Sections, no Front-Cover Texts,         ##
## and no Back-Cover Texts. A copy of the license is included in the     ##
## section entitled “GNU Free Documentation License”.                    ##
##                                                                       ##
## You should have received a copy of the GNU Free Documentation License ##
## along with The PBR. If not, see <http://www.gnu.org/licenses/>.       ##
## ********************************************************************* ##

#######################
# DO NOT EDIT THIS FILE
#######################

#   1) Do make a copy of Makefile.paths.original
#      as Makefile.paths
#   2) Edit Makefile.paths as directed there
#   3) This file (Makefile) and Makefile.paths.original
#      are managed by revision control and edits will conflict
#   4) See updated history in Makefile.paths.original
#      for changes, or follow the revision control history

##############
# Introduction
##############

# This is not a "true" makefile, since it does not
# operate on dependencies.  It is more of a shell
# script, sharing common configurations

######################
# System Prerequisites
######################

#   install         (system tool to make directories)
#   xsltproc        (xml/xsl text processor)
#   jing-trang      (only to check source against schema)
#   <helpers>       (PDF viewer, web browser, pager, Sage executable, etc)

#####
# Use
#####

#	A) Set default directory to be the location of this file
#	B) At command line:  make <some-target>

# The included file contains customized versions
# of locations of the principal components of this
# project and names of various helper executables
include Makefile.paths

# These paths are subdirectories of
# the PreTeXt distribution
# PTXUSR is where extension files get copied
# so relative paths work properly
PTXXSL = $(PTX)/xsl
PTXUSR = $(PTX)/user


IMAGESSRC = $(MAINDIR)/src/images
MAINFILE = $(MAINDIR)/src/ptx-basics-reference.ptx

# These paths are subdirectories of
# the scratch directory
HTMLOUT    = $(OUTPUT)/html
PDFOUT     = $(OUTPUT)/pdf
EPUBOUT    = $(OUTPUT)/epub
WWOUT      = $(OUTPUT)/webwork-extraction

# Some aspects of producing these examples require a WeBWorK server.
# We default to using the AIM-provided development server.
SERVER = https://webwork-ptx.aimath.org


################
#Targets for make
################

#  Extract webwork problems into a single XML file called
#  webwork-extraction.xml which holds multiple versions of each problem.
#  Also locally store images from the WeBWorK server.

pbr-extraction:
	install -d $(WWOUT)
	-rm $(WWOUT)/webwork-extraction.xml
	PYTHONWARNINGS=module $(PTX)/script/mbx -c webwork -d $(WWOUT) -s $(SERVER) $(MAINFILE)

pbr-merge:
	cd $(WWOUT); \
	xsltproc -xinclude  --stringparam webwork.extraction $(WWOUT)/webwork-extraction.xml $(PTXXSL)/pretext-merge.xsl $(MAINFILE) > pbr-merge.ptx

# Generate HTML output
# Output is:  $(HTMLOUT)/ptx-basics-reference.html
html: pbr-merge
	install -d $(OUTPUT)
	install -d $(HTMLOUT)
	-rm -rf $(HTMLOUT)/knowl
	-rm $(HTMLOUT)/*.html
	-rm -rf $(HTMLOUT)/images
	install -d $(HTMLOUT)/knowl
	cp -a $(IMAGESSRC) $(HTMLOUT)
	cd $(HTMLOUT); \
	xsltproc -xinclude -stringparam numbering.theorems.level 1 -stringparam numbering.projects.level 1 -stringparam numbering.equations.level 1 $(PTXXSL)/mathbook-html.xsl $(WWOUT)/pbr-merge.ptx

# Generate PDF output by first producing LaTeX and then compiling with
# ENGINE.
# Output is: $(PDFOUT)/ptx-basics-reference.pdf
pdf: pbr-merge
	install -d $(OUTPUT)
	install -d $(PDFOUT)
	install -d $(PDFOUT)/images
	-rm $(PDFOUT)/*.*
	-rm $(PDFOUT)/images/*
	-cp -a $(WWOUT)/*.png $(PDFOUT)/images
	cp -a $(IMAGESSRC) $(PDFOUT)
	cd $(PDFOUT); \
	xsltproc -o ptx-basics-reference.tex -xinclude -stringparam numbering.theorems.level 1 -stringparam numbering.projects.level 1 -stringparam numbering.equations.level 1 $(PTXXSL)/mathbook-latex.xsl $(WWOUT)/pbr-merge.ptx; \
	$(ENGINE) ptx-basics-reference; \
	$(ENGINE) ptx-basics-reference

###########
# Utilities
###########

# Verify Source integrity
#   Leaves "schema_errors.txt" in OUTPUT
check:
	install -d $(OUTPUT)
	-rm $(OUTPUT)/schema_errors.txt
	-java -classpath $(JINGTRANG) -Dorg.apache.xerces.xni.parser.XMLParserConfiguration=org.apache.xerces.parsers.XIncludeParserConfiguration -jar $(JINGTRANG)/jing.jar $(PTX)/schema/pretext.rng $(MAINFILE) > $(OUTPUT)/schema_errors.txt
	xsltproc --xinclude $(PTX)/schema/pretext-schematron.xsl $(MAINFILE) >> $(OUTPUT)/schema_errors.txt
	$(PAGER) $(OUTPUT)/schema_errors.txt
