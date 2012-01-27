/* 
 * Simple Brainfuck interpreter and x86-compiler written in D2
 * 2011
 * 
 */

import Brainfuck.Compiler;
import Brainfuck.Interpreter;
import Brainfuck.Parser;
import Brainfuck.EvalLoop;
import std.stdio;
import std.array;
import std.conv;

const version_num = 2;

string usage =
"Usage: bfc <OPTION> <SOURCE FILE> <OUT FILE>
Options:
	-i run <SOURCE FILE> in interpreter or run eval lopp if <SOURCE FILE> isn't set
	-c compile <SOURCE FILE> and write result to <OUT FILE>
	-h print this help and exit
	-v print version and exit\n";

string intro =
"This is interactive mode. Press ^D to exit.
Avaliable commands: 
	!dp                   print data pointer
	!dp <value>           set data pointer
	!ds <begin> <end>     print data\n";

int main(string[] args)
{
	if((args.length < 2) || (args.length > 4))
	{
		write(usage);
		return 1;
	}
	
	if(args[1] == "-h")
	{
		write(usage);
	}
	else if(args[1] == "-v")
	{
		writeln(version_num*0.1);
	}
	else if(args[1] == "-c")
	{
		if(args.length < 4)
		{
			writeln("No source or output file set");
			write(usage);
			return 1;
		}
		
		if(!CompilerIntelELF32.Compile(args[2],args[3]))
		{
			writeln("FAIL!");
			return 1;
		}
		else
			writeln("SUCCESS!");
	}
	else if(args[1] == "-i")
	{
		if(args.length < 3)
		{
			write(intro);
			
			EvalLoop lp = new EvalLoop();
			
			write("# ");
			
			char buf[];
			while(readln(buf))
			{
				lp.Eval(buf.idup);
				write("# ");
			}
			
			writeln("\n\nGood bye!");
		}
		else
		{
			Interpreter bf_interp = new Interpreter();
			if(!bf_interp.LoadFile(args[2]))
			{
				writeln("FAIL!");
				return 1;
			}
			else
			{
				bf_interp.Run();
			}
		}
	}
	else
	{
		writeln("Wrong option");
		write(usage);
		return 1;
	}
	
	return 0;
}
