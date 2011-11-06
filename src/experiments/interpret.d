import std.stdio;

struct cmd
{
	itp type;
	int arg;
}

enum itp
{ 
	I_CHANGE,
	I_SHIFT,
	I_LBEG,
	I_LEND,
	I_INP,
	I_OUTP
}

const MAX_CELLVAL = 255;
const MIN_CELLVAL = 0;

const MAX_CELLADDR = 30000;
const MIN_CELLADDR = 0;

const WARP_ADDR = true;
const WARP_VAL = true;
int[30000] data;
uint dp=0;
int main(string[] argv)
{	
	cmd[] code;
	//parse
	foreach(char c; argv[1])
	{
		switch (c)
		{
			case '+':
				code~=cmd(itp.I_CHANGE,1);
				break;
			case '-':
				code~=cmd(itp.I_CHANGE,-1);
				break;
			case '>':
				code~=cmd(itp.I_SHIFT,1);
				break;
			case '<':
				code~=cmd(itp.I_SHIFT,-1);
				break;
			case '[':
				code~=cmd(itp.I_LBEG,0);
				break;
			case ']':
				code~=cmd(itp.I_LEND,0);
				break;
			case '.':
				code~=cmd(itp.I_OUTP,0);
				break;
			case ',':
				code~=cmd(itp.I_INP,0);
				break;
			default:
				break;
		}
	}
	
	struct pair
	{
		enum { PAIR_UNDEF = -1 }
		
		int begin = PAIR_UNDEF;
		int end = PAIR_UNDEF;
	}
	
	pair[] loops;
	
	for(int i=0;i<code.length;i++)
	{
		if(code[i].type == itp.I_LBEG)
		{
			loops~=pair(i);
		}
		else if(code[i].type == itp.I_LEND)
		{
			foreach_reverse(ref pair p; loops)
			{
				if(p.end == pair.PAIR_UNDEF)
				{
					p.end = i;
					break;
				}
			}
		}
	}
	
	int ip = 0;
	run_loop: while(ip < code.length)
	{
		itp tp = code[ip].type;
			if(tp == itp.I_CHANGE)
			{
				if(code[ip].arg > 0)
					data[dp]++;
				else
					data[dp]--;
				
				data[dp]%=(MAX_CELLVAL);
			}
			else if(tp == itp.I_SHIFT)
			{
				if(code[ip].arg > 0)
					dp++;
				else
					dp--;
				
				dp%=(MAX_CELLADDR);
			}
			else if(tp ==  itp.I_LBEG)
			{
				if(data[dp] == 0)
				{
					foreach(pair p; loops)
					{
						if(p.begin == ip)
						{
							ip = p.end;
							break;
						}
					}
					//ip = loops[ip];
					continue run_loop;
				}
			}
			else if(tp == itp.I_LEND)
			{
				if(data[dp] != 0)
				{
					foreach(pair p;loops)
					{
						if(p.end == ip)
						{
							ip = p.begin;
							continue run_loop;
						}
					}
				}
			}
			else if(tp ==  itp.I_INP)
			{
				data[dp] = ' ';
			}
			else if(tp == itp.I_OUTP)
			{
				write(cast(char)data[dp]);
			}
		
		
		ip++;
	}

	return 0;
}