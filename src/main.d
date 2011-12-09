/* 
 * Simple Brainfuck interpreter and x86-compiler written in D2
 * 2011
 * 
 */

import Brainfuck.Compiler;
import Brainfuck.Interpreter;
import Brainfuck.Parser;
import std.stdio;
import std.array;
import std.conv;

const version_num = 1;

string usage =
"Usage: bfc <OPTION> <SOURCE FILE> <OUT FILE>
Options:
	-i run <SOURCE FILE> in interpreter or run eval lopp if <SOURCE FILE> isn't set
	-c compile <SOURCE FILE> and write result to <OUT FILE>
	-h print this help and exit
	-v print version and exit\n";

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
			/* TODO: move it to header */
			writeln("You are in read-eval-print loop. Press ^D to exit.");
			writeln("Avaliable commands:");
			writeln("\t!dp                  display data pointer");
			writeln("\t!dp <value>          set data pointer");
			writeln("\t!ds <begin> <end>    print data values");

			write("# ");
			
			auto bf_parser = new Parser();
			auto bf_interp = new Interpreter();
			
			char[] input_buf;
			while(readln(input_buf))
			{
				if((input_buf[0]=='!') && ((input_buf == "!ds\n") || (input_buf[0..4] == "!ds ")))
				{
					int begin,end;
					char params[][];

					if(input_buf.length > "!ds\n".length)
						params = split(input_buf[4..input_buf.length-1]);

					if(params.length > 0)
					{
						try
						{
							begin = to!(uint)(params[0]);

							if(params.length > 1)
							{
								end = to!(uint)(params[1]);

								if(end < begin)
									throw new ConvException("begin > end");
							}
							else
								end = begin;
						}
						catch(ConvException conv_err)
						{
							writeln("Wrong arguments");
							begin = end = -1;
						}
					}
					else
					{
						begin = end = bf_interp.GetDataPtr();
					}


					if(begin >= 0)
					{
						if(end < 0) end = begin; 
						foreach(ubyte b;bf_interp.GetData()[begin..end+1])
							write(b," ");
						writeln();
					}
				}
				else if((input_buf[0]=='!') && (input_buf[0..3] == "!dp") && input_buf.length==4)
				{
					writeln("Data pointer: ",bf_interp.GetDataPtr());
				}
				else if((input_buf[0]=='!') && (input_buf[0..4] == "!dp "))
				{
					int new_data_ptr = to!(uint)(input_buf[4..input_buf.length-1]);
					bf_interp.SetDataPtr(new_data_ptr);
					writeln("New data pointer: ",new_data_ptr);
				}
				else
				{
					bf_parser.SetSourceFromText(input_buf);
					Parser.ParseError err;
					uint err_pos;
					err = bf_parser.Validate(err_pos);
				
					if(err != Parser.ParseError.None)
					{
						if(err == Parser.ParseError.UnmatchedLeftBrace)
							writeln("Error: unmatched [ at ",err_pos);
						else if(err == Parser.ParseError.UnmatchedRightBrace)
							writeln("Error: unmatched ] at ",err_pos);
					
						return false;
					}
					
					bf_interp.SetCode(bf_parser.Parse());
					bf_interp.Run();
					
					bf_interp.SetIndex(0);
				}
				write("\n# ");
			}
			writeln("\nGood bye!");
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
