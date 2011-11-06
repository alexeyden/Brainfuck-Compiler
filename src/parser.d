module Brainfuck.Parser;
import std.stdio;

class Parser
{
	public:
		this() {}
		this(string filename) { SetSourceFromFile(filename); }

		enum ParseError
		{
			None,
			UnmatchedLeftBrace,
			UnmatchedRightBrace,
			NoSourceCode
		}

		enum CommandType
		{
			Change,
			Move,
			LoopBegin,
			LoopEnd,
			Input,
			Output
		}

		struct Command
		{
			CommandType type;
			int arg;
		}

		bool SetSourceFromFile(string filename)
		{
			File file;
			
			try
			{
				file = File(filename,"r");

				char[] line_buf;

				while(file.readln(line_buf))
					code ~= line_buf;
			}
			catch(Exception fe)
			{
				file.close();

				code = [];

				return false;
			}


			file.close();

			return true;
		}
		
		void SetSourceFromText(char[] text)
		{
			code = text;
		}

		ParseError Validate(out uint err_pos)
		{
			err_pos = 0;

			if(!code)
				return ParseError.NoSourceCode;

			
			uint[] braces;
			
			//check matching braces
			foreach(int i,char c; code)
			{
				if(c == '[')
				{
					braces ~= i;
				}
				else if(c == ']')
				{
					if(braces.length != 0)
					{
						braces.length = braces.length - 1;
					}
					else
					{
						err_pos = i;
						return ParseError.UnmatchedRightBrace;
					}
				}
			}

			if(braces.length != 0)
			{
				err_pos = braces[braces.length - 1];
				return ParseError.UnmatchedLeftBrace;
			}

			return ParseError.None; 
		}

		Command[] Parse()
		{
			Command[] parsed;
			
			uint err;
			
			if(Validate(err) != ParseError.None)
			{
				return parsed;
			}
			
			/* First pass:
			 * translate commands into internal representation
			 */

			//cache for repeating commands (+,-,>,<)
			int change_n = 0;
			int shift_n = 0;

			foreach(int idx,char c; code)
			{
				//flush cache
				if((c != '+') && (c != '-') && (change_n != 0))
				{
					parsed ~= Command(CommandType.Change, change_n);
					change_n = 0;
				}
				if((c != '>') && (c != '<') && (shift_n != 0))
				{
					parsed ~= Command(CommandType.Move,shift_n);
					shift_n = 0;
				}

				switch (c)
				{
					case '+': change_n++; break;
					case '-': change_n--; break;
					case '>': shift_n++;  break;
					case '<': shift_n--;  break;
					case '[':
						parsed ~= Command(CommandType.LoopBegin,-1);
						break;
					case ']':
						parsed ~= Command(CommandType.LoopEnd,-1);
						break;
					case '.':
						parsed ~= Command(CommandType.Output,0);
						break;
					case ',':
						parsed ~= Command(CommandType.Input,0);
						break;
					default:
						break;
				}
			}

			//flush cache if code ends with +,- or <,>
			if(change_n != 0)
				parsed ~= Command(CommandType.Change, change_n);
			if(shift_n != 0)
				parsed ~= Command(CommandType.Move, shift_n);

			/* Second pass:
			 * find matching loop braces
			 */
			for(int i = 0; i < parsed.length; i++)
			{
				if(parsed[i].type == CommandType.LoopEnd)
				{
					for(int j = i; j >= 0; j--)
					{
						if(parsed[j].type == CommandType.LoopBegin && parsed[j].arg == -1)
						{
							parsed[j].arg = i;
							parsed[i].arg = j;
							break;
						}
					}
				}
			}

			return parsed;
		}
	
	private:
		char[] code;

}
