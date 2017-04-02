#!/bin/sh

[ -f "$1" ] || { echo >&2 "Usage: $0 BF_Program"; exit 1;}

P="$(dirname "$0")"

echo "Correct      :$(
ruby <<\! - "$1" |
eval 'm=Hash.new(p=0);'+ARGF.read.gsub(
	/./,
	'>' => 'p+=1;',
	'<' => 'p-=1;',
	'+' => 'm[p]+=1;',
	'-' => 'm[p]-=1;',
	'[' => '(',
	']' => ')while((m[p]&=255)!=0);',
	'.' => 'putc m[p];',
	',' => 'm[p]=STDIN.getbyte if !STDIN.eof;')
!
xxd -g0 -l18 -c18
)"

for i in "$P"/broken-bf?.c
do  echo $(basename "$i") :"$(
    ( ulimit -t 2 ; tcc -run $i "$1" </dev/null |
    xxd -g0 -l18 -c18 ) 2>&1 )"
done


