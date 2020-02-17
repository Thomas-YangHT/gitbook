Pjname=linuxcommand
Port=8000

tee >mkdocs.yml <<EOF
site_name:  $Pjname
nav:
   - Home: index.md   
`(cd docs;find * -name "*.md")|grep -vP  "index.md|about.md" |iconv -f gbk -t utf-8|awk '{print "   - "$0}'`
   - About: about.md
theme: readthedocs 
EOF
