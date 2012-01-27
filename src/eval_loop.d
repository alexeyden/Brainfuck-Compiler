module Brainfuck.EvalLoop;
import Brainfuck.Interpreter;
import Brainfuck.Parser;
import std.stdio;
import std.conv;
import std.string;

class EvalLoop : Interpreter
{
	public:
	this() { super(); parser = new Parser();}
	
	bool Eval(string text)
	{
		if(text.length < 1)
			return false;
		
		if(text[0] == cmd_prefix)
		{
			string[] params = split(text);
			
			if(!this.ProcessCommand(params))
			{
				writeln("Wrong command");
				return false;
			}
		}
		else
		{
			parser.SetSourceFromText(text.dup);
			
			Parser.ParseError err;
			uint err_pos;
			err = parser.Validate(err_pos);
				
			if(err != Parser.ParseError.None)
			{
				writeln("PARSER ERROR!");
				
				if(err == Parser.ParseError.UnmatchedLeftBrace)
					writeln("Unmatched [ at ",err_pos);
				else if(err == Parser.ParseError.UnmatchedRightBrace)
					writeln("Unmatched ] at ",err_pos);
				
				return false;
			}
			
			this.SetCode(parser.Parse());
			this.Run();
			this.SetIndex(0);
		}

		return true;
	}
	
protected:
	bool ProcessCommand(string[] cmd)
	{	
		if(cmd[0] == cmd_dvalues)
		{
			int begin, end;
			
			//do we have some args?
			if(cmd.length > 1)
			{
				//get one byte
				if(cmd.length == 2)
				{
					begin = 0;
					try { end = to!(uint)(cmd[1]); }
					catch(ConvException conv_err)
						return false;
				}
				//get slice
				else if(cmd.length == 3)
				{
					try
					{
						begin = to!(uint)(cmd[1]);
						end = to!(uint)(cmd[2]);
						
						if(end < begin)
							throw new ConvException("begin > end");
					}
					catch(ConvException e)
						return false;
				}
				else
					return false;
			}
			else //get currently seclected data byte
				begin = end = GetDataPtr();
			
			writeln("DATA ",begin,"..",end,":");
			for(;begin <= end;begin++)
				write(this.GetData()[begin],' ');
			writeln();
		}
		else if(cmd[0] == cmd_dptr)
		{
			if(cmd.length == 2)
			{
				try
				{
					int new_data_ptr = to!(uint)(cmd[1]);
					this.SetDataPtr(new_data_ptr);
					writeln("NEW DATA POINTER: ",new_data_ptr);
				}
				catch(ConvException e)
					return false;
			}
			else if(cmd.length == 1)
				writeln("DATA POINTER: ",this.GetDataPtr());
			else
				return false;
		}
		else //wrong command
			return false;
		
		return true;
	}
	
	private:
	Parser parser;
	const string cmd_dptr = "!dp";
	const string cmd_dvalues = "!ds";
	const char cmd_prefix='!';
}
