/*
 * This is a converter for various Brainfuck equivalents.
 *
 * It also contains the "deadbeef" interpreter for running the converted code.
 */
%{
#include <stdio.h>
#include <string.h>

#define STFU(expression) (expression)	/* Make GCC ... */

#define MAXCOL 72
static void pc(int);
static void commentch(int);
static void pcr(int, int);
static int countch(char *, int);
static void pcs(int, int);

static int uncomment_mode = 0;
static int bfcomment = 0;

#define YY_INPUT(buf,result,max_size) result = bf_prefilter(buf,max_size)
size_t bf_prefilter(char * buf, size_t maxsize);

%}
    /* Not using these, make GCC STFU. */
%option noinput
%option nounput

    /* Probably case insensitive ... */
%option case-insensitive
%option noyywrap
%option nodefault

%s BFRLE
%s BFRLE2
%s OOK
%s BLUB
%s POG
%s ALWORD
%s FK
%x CCOMMENT
%x BFCOMMENT
%x ZZZ
%x TRIP
%x PETOOH
%x SPOON

w	[\t ]*
ws	[\t ]+
wl	[\t\n ]*
num	[0-9]+

twoc	[A-Za-z*][A-Za-z*]
pock	([ \t\n]*pock!)*
ook	B?[Oo]ok

%%
<INITIAL>[]<+,-.>[]		pc(yytext[0]);

<BFRLE>{
    \[				{
				    BEGIN(BFCOMMENT);
				    bfcomment++;
				    commentch('[');
				}
    =				;
}

<BFRLE2>{
    \[				pc(yytext[0]);
    =				{
				    BEGIN(BFRLE);
				    pcr('=', 0);
				}
}

<BFRLE,BFRLE2>{
    \]				{ BEGIN(BFRLE); pc(yytext[0]); }
    [<+,-.>]			{ BEGIN(BFRLE2); pc(yytext[0]); }

    {num}{w}[-+><=]		{
				    int ch=yytext[yyleng-1];
				    BEGIN(BFRLE2);
				    yytext[yyleng-1] = 0;
				    pcr(ch, atoi(yytext));
				}

    \"[^"\n\\]*\"		{
				    int i;
				    BEGIN(BFRLE2);
				    for(i=1; i<yyleng-1; i++) {
					pcr('=', yytext[i]);
					pc('.');
				    }
				}

    \/\/.*		{int i; for(i=1; i<yyleng; i++) commentch(yytext[i]);}
    "/*"		{ uncomment_mode = YY_START; BEGIN(CCOMMENT); }
}

<BFCOMMENT>{

    \]		{
		    commentch(yytext[0]);
		    bfcomment--;
		    if (bfcomment == 0) {
			BEGIN(BFRLE);
		    }
		}
    \[		{
		    bfcomment++;
		    commentch(yytext[0]);
		}

    \/\/.*	{int i; for(i=1; i<yyleng; i++) commentch(yytext[i]);}
    "/*"	{ uncomment_mode = YY_START; BEGIN(CCOMMENT); }

    [^]\/\n[]+	|
    \/		|
    \n		{int i; for(i=0; i<yyleng; i++) commentch(yytext[i]);}
    <<EOF>>	{   fprintf(stderr, "WARNING: End of file in BF comment\n");
		    yyterminate(); }
}

<OOK>{
    {ook}\.[ \t\n]*{ook}\?	pc('>');
    {ook}\?[ \t\n]*{ook}\.	pc('<');
    {ook}\.[ \t\n]*{ook}\.	pc('+');
    {ook}![ \t\n]*{ook}!	pc('-');
    {ook}![ \t\n]*{ook}\.	pc('.');
    {ook}\.[ \t\n]*{ook}!	pc(',');
    {ook}![ \t\n]*{ook}\?	pc('[');
    {ook}\?[ \t\n]*{ook}!	pc(']');
}

<BLUB>{
    blub\.[ \t\n]*blub\?	pc('>');
    blub\?[ \t\n]*blub\.	pc('<');
    blub\.[ \t\n]*blub\.	pc('+');
    blub![ \t\n]*blub!  	pc('-');
    blub![ \t\n]*blub\. 	pc('.');
    blub\.[ \t\n]*blub! 	pc(',');
    blub![ \t\n]*blub\? 	pc('[');
    blub\?[ \t\n]*blub! 	pc(']');
}

<FK>{
    f{twoc}k!*		pcr('>', yyleng-3);
    s{twoc}g!*		pcr('<', yyleng-3);
    b{twoc}b!*		pcr('+', yyleng-3);
    t{twoc}s!*		pcr('-', yyleng-3);
    c{twoc}k!*		pcr('.', yyleng-3);
    k{twoc}b!*		pcr(',', yyleng-3);
    a{twoc}e!*		pcr('[', yyleng-3);
    b{twoc}t!*		pcr(']', yyleng-3);
    "/*"		{ uncomment_mode = YY_START; BEGIN(CCOMMENT); }
}

<CCOMMENT>{
    "*/"	BEGIN(uncomment_mode);
    [^*\n]+	|
    "*"		|
    \n		{int i; for(i=0; i<yyleng; i++) commentch(yytext[i]);}
    <<EOF>>	{   fprintf(stderr, "WARNING: End of file in /* comment\n");
		    yyterminate(); }
}

<POG>{
    pogack!{pock}		pcr('>', countch(yytext, '!'));
    pogaack!{pock}		pcr('<', countch(yytext, '!'));
    pogaaack!{pock}		pcr('+', countch(yytext, '!'));
    poock!{pock}		pcr('-', countch(yytext, '!'));
    pogaaack\?{pock}		pcr('.', countch(yytext, '!')+1);
    poock\?{pock}		pcr(',', countch(yytext, '!')+1);
    pogack\?{pock}		pcr('[', countch(yytext, '!')+1);
    pogaack\?{pock}		pcr(']', countch(yytext, '!')+1);
}

<ZZZ>{
    "zz"	pc('>');
    "-zz"	pc('<');
    "z"		pc('+');
    "-z"	pc('-');
    "zzz"	pc('.');
    "-zzz"	pc(',');
    "z+z"	pc('[');
    "z-z"	pc(']');

    [ \t\n]+	{int i; for(i=0; i<yyleng; i++) commentch(yytext[i]);}
    .		commentch(yytext[0]);
}

<TRIP>{
    001		pc('>');
    100		pc('<');
    111		pc('+');
    000		pc('-');
    010		pc('.');
    101		pc(',');
    110		pc('[');
    011		pc(']');

    [ \t\n]+	{int i; for(i=0; i<yyleng; i++) commentch(yytext[i]);}
    .		commentch(yytext[0]);
}

<PETOOH>{
    (?-i:Kudah)		pc('>');
    (?-i:kudah)		pc('<');
    (?-i:Ko)		pc('+');
    (?-i:kO)		pc('-');
    (?-i:Kukarek)	pc('.');
    (?-i:kukarek)	pc(',');
    (?-i:Kud)		pc('[');
    (?-i:kud)		pc(']');

    [ \t\n]+	{int i; for(i=0; i<yyleng; i++) commentch(yytext[i]);}
    .		commentch(yytext[0]);
}

<SPOON>{
    1		pc('+');
    000		pc('-');
    010		pc('>');
    011		pc('<');
    0011	pc(']');
    00100	pc('[');
    001010	pc('.');
    0010110	pc(',');
    00101110	pc('#');
    00101111	;

    [ \t\n]+	{int i; for(i=0; i<yyleng; i++) commentch(yytext[i]);}
    .		commentch(yytext[0]);
}

<ALWORD>{
    /* Simple "words". These sets don't interfere with each-other. */

    right		pcs('>', 0);
    left		pcs('<', 0);
    up			pcs('+', 0);
    down		pcs('-', 0);
    out			pcs('.', 0);
    in			pcs(',', 0);
    begin		pcs('[', 0);
    end			pcs(']', 0);

    fnord		pcs('>', 1);	/* BrainFNORD */
    pineal		pcs('<', 1);
    hail		pcs('+', 1);
    eris		pcs('-', 1);
    kallisti		pcs('.', 1);
    chaos		pcs(',', 1);
    23			pcs('[', 1);
    5			pcs(']', 1);

    pipi		pcs('>', 2);	/* Pikalang */
    pichu		pcs('<', 2);
    pi			pcs('+', 2);
    ka			pcs('-', 2);
    pikachu		pcs('.', 2);
    pikapi		pcs(',', 2);
    pika		pcs('[', 2);
    chu			pcs(']', 2);

    there		pcs('<', 3);	/* There Once was a Fish Named Fred */
    once		pcs('>', 3);
    was			pcs('+', 3);
    a			pcs('-', 3);
    fish		pcs('.', 3);
    named		pcs('[', 3);
    fred		pcs(']', 3);

    "(.)(.)"		pcs('>', 4);
    "(.){.}"		pcs('<', 4);
    "(.)[.]"		pcs('+', 4);
    "[.](.)"		pcs('-', 4);
    "[.][.]"		pcs('.', 4);
    "{.}{.}"		pcs(',', 4);
    "{.}[.]"		pcs('[', 4);
    "[.]{.}"		pcs(']', 4);

    右			pcs('>', 5);
    左			pcs('<', 5);
    上			pcs('+', 5);
    下			pcs('-', 5);
    出			pcs('.', 5);
    里			pcs(',', 5);
    始			pcs('[', 5);
    末			pcs(']', 5);

    "(("		pcs('>', 6);
    "))"		pcs('<', 6);
    "()("		pcs('+', 6);
    "())"		pcs('-', 6);
    ")())"		pcs('.', 6);
    ")((("		pcs(',', 6);
    ")()("		pcs('[', 6);
    ")(()"		pcs(']', 6);
}

\001.*		{int i; for(i=1; i<yyleng; i++) commentch(yytext[i]);}

[A-Za-z0-9]+	|
[ \t\n]+	{int i; for(i=0; i<yyleng; i++) commentch(yytext[i]);}
.		commentch(yytext[0]);
%%

void addcmd(int, int);
void run(void);
struct bfi { int mov; int cmd; int arg; } *pgm = 0;
int pgmlen = 0;
int jmp = -1, cp = -1, pp = -1;
int on_eof = 1, runit = 0, debug = 0;

int sof = 1, cln = 0, col = 0, ccol = 0;
int alset = 0;

int quiet = 0;

char * character_prefilter = 0;
char * character_conversion = 0;
int line_cc = EOF;

char bf[] = "><+-.,[]#";

size_t (*custom_prefilter)(char *, size_t) = 0;
size_t tiny_bf_to_bf(char * buf, size_t max_size);
size_t qqq_to_bf(char * buf, size_t max_size);

int main(int argc, char ** argv)
{
    int mode = INITIAL;
    int enable_opts = 1;

    char ** filelist = 0;
    int ar, filecount = 0;

    filelist = calloc(argc, sizeof *filelist);

    while(argc>1)
    {
	if(argv[1][0] == '-' && enable_opts) {
	    if (!strcmp(argv[1], "--")) enable_opts = 1;
	    else if (!strcmp(argv[1], "-r")) runit = 1;

	    else if (!strcmp(argv[1], "-e")) on_eof = -1;
	    else if (!strcmp(argv[1], "-z")) on_eof = 0;
	    else if (!strcmp(argv[1], "-n")) on_eof = 1;
	    else if (!strcmp(argv[1], "-d")) debug = 1;
	    else if (!strcmp(argv[1], "-q")) quiet = 1;

	    else if (!strcmp(argv[1], "-chash")) line_cc = '#';
	    else if (!strcmp(argv[1], "-cslash")) line_cc = '/';
	    else if (!strcmp(argv[1], "-csemi")) line_cc = ';';
	    else if (!strcmp(argv[1], "-nocom")) line_cc = EOF;

	    else if (!strcmp(argv[1], "-bfrle")) { mode = BFRLE; }

	    else if (!strcmp(argv[1], "-ook")) { mode = OOK; line_cc = '/'; }
	    else if (!strcmp(argv[1], "-blub")) mode = BLUB;
	    else if (!strcmp(argv[1], "-pog")) mode = POG;
	    else if (!strcmp(argv[1], "-fk")) mode = FK;
	    else if (!strcmp(argv[1], "-zzz")) mode = ZZZ;

	    else if (!strcmp(argv[1], "-nice")) { mode = ALWORD; alset = 0; }
	    else if (!strcmp(argv[1], "-eris")) { mode = ALWORD; alset = 1; }
	    else if (!strcmp(argv[1], "-pika")) { mode = ALWORD; alset = 2; }
	    else if (!strcmp(argv[1], "-fish")) { mode = ALWORD; alset = 3; }
	    else if (!strcmp(argv[1], "-bewbs")) { mode = ALWORD; alset = 4; }
	    else if (!strcmp(argv[1], "-chi")) { mode = ALWORD; alset = 5; }
	    else if (!strcmp(argv[1], "-lisp")) { mode = ALWORD; alset = 6; character_prefilter="()"; }

	    else if (!strcmp(argv[1], "-mini")) {
		mode = INITIAL;
		character_prefilter = "rludoibe";
		character_conversion = bf;
	    }
	    else if (!strcmp(argv[1], "-alphuck")) {
		mode = INITIAL;
		character_prefilter = "aceijops";
		character_conversion = bf;
	    }
	    else if (!strncmp(argv[1], "-bf=", 4) && strlen(argv[1]) <= 13) {
		mode = INITIAL;
		character_prefilter = argv[1]+4;
		character_conversion = bf;
	    }
	    else if (!strcmp(argv[1], "-petooh")) {
		mode = PETOOH;
		character_prefilter = "adehkKoOru";
	    }

	    else if (!strcmp(argv[1], "-trip")) {
		mode = TRIP;
		character_prefilter = "01";
	    }

	    else if (!strcmp(argv[1], "-spoon")) {
		mode = SPOON;
		character_prefilter = "01";
	    }

	    else if (!strcmp(argv[1], "-tinybf")) {
		mode = INITIAL;
		custom_prefilter = tiny_bf_to_bf;
	    }

	    else if (!strcmp(argv[1], "-???") || !strcmp(argv[1], "-qqq")) {
		mode = INITIAL;
		custom_prefilter = qqq_to_bf;
	    }

	    else {
		fprintf(stderr, "Unknown option %s\n", argv[1]);
		exit(1);
	    }
	    argv++, argc--;
	    continue;
	}

	filelist[filecount++] = argv[1];
	argv++, argc--;
    }
    if (filecount == 0)
	filelist[filecount++] = "-";

    for(ar=0; ar<filecount; ar++)
    {
	if(strcmp(filelist[ar], "-")) {
	    if (!(yyin = fopen(filelist[ar], "r"))) {
		perror(filelist[ar]);
		exit(1);
	    }
	    yyrestart(yyin);
	}

	BEGIN(mode);
	yylex();

	if(strcmp(filelist[ar], "-"))
	    fclose(yyin);

	if (col || ccol) putchar('\n'), ccol = col = 0;
	if (sof > 1) { printf("]*/\n"); sof = 0; }
    }

    if (pgm) {
	pgm[cp+1].cmd = 0;
	while(jmp>=0)
	{ pp=jmp; jmp=pgm[jmp].arg; pgm[pp].arg=0; pgm[pp].cmd = '+'; }
	setbuf(stdout, NULL);
	run();
    }
    return 0;
}

static void
pcs(int ch, int inset)
{
    if (inset != alset)
    {
	int i;
	for(i=0; i<yyleng; i++)
	    commentch(yytext[i]);
    } else
	pc(ch);
}

static void
pc(int ch)
{
    if (runit) {
	addcmd(ch, 1);
	return;
    }
    if (sof) {
	while(cln-->0) putchar(']');
	if (sof == 2) printf("\n]");
	sof = 0;
    }
    if (ccol) putchar('\n'), ccol = col = 0;
    putchar(ch);
    if (++col >= MAXCOL) putchar('\n'), col = 0;
}

static void commentch(int ch)
{
    if (runit || quiet) return;
    if (sof == 1 && bfcomment) sof = 0;
    if (sof == 1) { printf("[\n"); sof = 2; }
    if ((ccol == 0) && (ch == '\n' || ch == '\t' || ch == ' ')) return;

    /* Only output characters we don't use in BF. Plus a comment loop. */
    if (sof) {
	if (ch == '[') cln++;
	else if (ch == ']') {
	    if (cln > 0) cln--;
	    else ch = ':';
	}
    } else if (bfcomment == 0 &&
	       (ch == '+' || ch == '-' || ch == '#' || ch == '[' || ch == ']' ||
		ch == '.' || ch == ',' || ch == '>' || ch == '<' ))
	ch = ':';

    if (col) putchar('\n'), ccol = col = 0;
    if (ccol <	0) ccol += printf("\n");
    if (ccol == 0 && !sof && !bfcomment) ccol += printf("//%s", (ch=='\t' || ch =='\n') ? "" : " ");
    if (ch == '\n') ccol = -1;
    else {
	ccol++;
	putchar(ch);
    }
}

static void pcr(int ch, int count)
{
    if (ch == '=') {
	pc('['); pc('-'); pc(']');
	ch = '+';
    }
    if (runit) addcmd(ch, count);
    else while(count-->0) pc(ch);
}

static int countch(char * s, int ch)
{
    int rv = 0;
    if(s) while(*s) rv += (*s++ == ch);
    return rv;
}

/*
 * This preprocesses the source before lex gets to see it.
 *
 * The first thing it does is to turn unknown control characters into spaces,
 * this is so I can use them to simulate a changable regex for line comments.
 *
 * The second process is elimination of all non-command characters for
 * variants that don't like embeded spaces. Some of these are simple
 * BF character transliterations so the third process is the ability
 * to change these direct conversions to pure BF in this preprocessing
 * stage.
 */
size_t
bf_prefilter(char * buf, size_t max_size)
{
    size_t n;
    int c = 0xDEADBEEF;
    if (custom_prefilter)
	return custom_prefilter(buf, max_size);
    else if (!character_prefilter && line_cc == EOF) {
	for ( n = 0; n < max_size && (c = getc( yyin )) != EOF && c != '\n';) {
	    if (c>=0 && c<' ' && c!='\t')
		c = ' ';
	    buf[n++] = (char) c;
	}
	if (c == '\n')
	    buf[n++] = (char) c;
    } else {
	/* NB: If we're preprocessing don't bother trying to line buffer. */
	for ( n = 0; n < max_size && (c = getc( yyin )) != EOF;) {
	    char * p;
	    if (c == line_cc) c = '\001';
	    else if (c>=0 && c<' ' && c!='\t' && c!='\n') c = ' ';

	    if (!character_prefilter)
		buf[n++] = (char) c;
	    else if(STFU(p=strchr(character_prefilter, c))) {
		if (character_conversion)
		    buf[n++] = character_conversion[p-character_prefilter];
		else
		    buf[n++] = (char) c;
	    }
	}
    }
    if ( c == EOF && ferror( yyin ) )
	YY_FATAL_ERROR( "input in flex scanner failed" );
    return n;
}

size_t
tiny_bf_to_bf(char * buf, size_t max_size)
{
    static int tbf_dir = 0;
    static int lookahead[8];
    static int lookahead_len;

    size_t n;
    int c, more;

    for(n=0; n<max_size;) {
	c = getc(yyin);
	if (c == EOF) return n;
	if (c == '\n') {
	    buf[n++] = c;	       /* Keep shorter lines. */
	    continue;
	} else
	if (c != '=' && c != '+' && c != '>' && c != '|')
	    continue;

	lookahead[lookahead_len++] = c;

	for(more=0; !more && n<max_size;)
	{
	    int eat=1;
	    c = *lookahead;
	    switch(c)
	    {
	    case '+': buf[n++] = "+-"[tbf_dir]; break;
	    case '>': buf[n++] = "><"[tbf_dir]; break;
	    case '=':
		switch(lookahead[1])
		{
		case 0: eat=0; break;
		case '=': buf[n++] = '.'; eat=2; break;
		default: tbf_dir = !tbf_dir; break;
		}
		break;
	    case '|':
		if (tbf_dir) {
		    buf[n++] = ']';
		} else
		    switch(lookahead[1])
		    {
		    case 0: eat=0; break;
		    case '=':
			switch(lookahead[2])
			{
			case 0: eat=0; break;
			case '|': buf[n++] = '.'; eat=3; break;
			default: buf[n++] = '['; break;
			}
			break;
		    default: buf[n++] = "[]"[tbf_dir]; break;
		    }
		break;
	    }

	    more = !eat;
	    for(; eat>0; eat--) {
		int i;
		for(i=1; STFU(lookahead[i-1] = lookahead[i]); i++) ;
		lookahead_len--;
	    }
	    if (!*lookahead) more = 1;
	}
    }
    return n;
}

size_t
qqq_to_bf(char * buf, size_t max_size)
{
    static int qqq_state = 0;

    size_t n;
    int c;

    for(n=0; n<max_size;) {
	c = getc(yyin);
	if (c == EOF) return n;

	switch(c)
	{
	case '\n': buf[n++] = '\n'; break;	/* Keep shorter lines. */
	case ';': buf[n++] = '>'; break;
	case '-': buf[n++] = '<'; break;
	case '.': buf[n++] = '+'; break;
	case ',': buf[n++] = '-'; break;
	case '!': buf[n++] = '.'; break;
	case '?': buf[n++] = ','; break;

	case '\'': qqq_state = 1-qqq_state; break;
	case '"':
	    if (qqq_state == 0)
		buf[n++] = '[';
	    else
		buf[n++] = ']';
	}
    }
    return n;
}

/*****************************************************************************
 * This is the "deadbeef" brainfuck interpreter.
 */
void addcmd(int ch, int cnt)
{
    int r = (ch == '<' || ch == '>' || ch == '+' || ch == '-');
    if (!r && cnt != 1) {
	while(cnt-->0) addcmd(ch, 1);
	return;
    }
    if (r) r = cnt;

    if (r || (debug && ch == '#') || (ch == ']' && jmp>=0) ||
	ch == '[' || ch == ',' || ch == '.') {
	if (ch == '<') { ch = '>'; r = -r; }
	if (ch == '-') { ch = '+'; r = -r; }
	if (r && pp>=0 && pgm[pp].cmd == ch) { pgm[pp].arg += r; return; }
	if (pp>=0 && pgm[pp].cmd == '=' && ch == '+')
	{ pgm[pp].arg += r; return; }
	if (pp>=0 && pgm[pp].cmd == '>') { pgm[pp].mov = pgm[pp].arg; }
	else {
	    cp++;
	    if (cp>= pgmlen-2) pgm = realloc(pgm, (pgmlen=cp+99)*sizeof *pgm);
	    if (!pgm) { perror("realloc"); exit(1); }
	    pgm[cp].mov = 0;
	}
	pgm[cp].cmd = ch; pgm[cp].arg = r; pp = cp;
	if (pgm[cp].cmd == '[') { pgm[cp].arg=jmp; jmp = cp; }
	else if (pgm[cp].cmd == ']') {
	    pgm[cp].arg = jmp; jmp = pgm[jmp].arg; pgm[pgm[cp].arg].arg = cp;
	    if (  pgm[cp].mov == 0 && pgm[cp-1].mov == 0 &&
		  pgm[cp-1].cmd == '+' && (pgm[cp-1].arg&1) == 1 &&
		  pgm[cp-2].cmd == '[') {
		cp -= 2; pgm[pp=cp].cmd = '='; pgm[cp].arg = 0;
	    } else if (pgm[cp-1].cmd == '[') {
		cp--; pgm[pp=cp].cmd = '?'; pgm[cp].arg = pgm[cp+1].mov;
	    }
	}
    }
}

void run(void)
{
    static unsigned char t[1+(unsigned short)-1];
    unsigned short m = 0;
    int n, ch;
    for(n=0;; n++) {
	m += pgm[n].mov;
	switch(pgm[n].cmd)
	{
	case 0:	   return;
	case '=':  t[m] = pgm[n].arg; break;
	case '+':  t[m] += pgm[n].arg; break;
	case '[':  if (t[m] == 0) n=pgm[n].arg; break;
	case ']':  if (t[m] != 0) n=pgm[n].arg; break;
	case '?':  while(t[m]) m += pgm[n].arg; break;
	case '>':  m += pgm[n].arg; break;
	case '.':  putchar(t[m]); break;
	case ',':
	    if((ch=getchar())!=EOF) t[m]=ch;
	    else if (on_eof != 1) t[m]=on_eof;
	    break;
	case '#':
	    fprintf(stderr, "\n%3d %3d %3d %3d %3d %3d %3d %3d %3d %3d\n%*s\n",
		    t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9],
		    4*m+3, "^");
	    break;
	}
    }
}
