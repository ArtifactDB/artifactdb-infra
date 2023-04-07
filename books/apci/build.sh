# requires pandoc-include: pip install pandoc-include
dir=$(basename `pwd`)
pandoc $dir.md --from markdown --template "../templates/eisvogel.tex" --listings --top-level-division="chapter" --filter pandoc-include --filter pandoc-mustache -o "$dir.pdf" 
