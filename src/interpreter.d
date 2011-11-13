module Brainfuck.Interpreter;
import Brainfuck.Parser;
import std.stdio;

class Interpreter
{
public:
	this(){}
	this(string filename) { LoadFile(filename); }
	
	bool LoadFile(string filename)
	{
		Parser bf_parser = new Parser();
		if(!bf_parser.SetSourceFromFile(filename))
		{
			writeln("INPUT FILE ERROR!");
			writeln("Can not read souce file: ",filename);
			return false;
		}
		
		Parser.ParseError err;
		uint err_pos;
		err = bf_parser.Validate(err_pos);
			
		if(err != Parser.ParseError.None)
		{
			writeln("PARSER ERROR!");
			
			if(err == Parser.ParseError.UnmatchedLeftBrace)
				writeln("Unmatched [ at ",err_pos);
			else if(err == Parser.ParseError.UnmatchedRightBrace)
				writeln("Unmatched ] at ",err_pos);
			
			return false;
		}
		
		this.code = bf_parser.Parse();
		return true;
	}
	
	void SetCode(Parser.Command[] code) { this.code = code; }
	Parser.Command[] GetCode() { return code; }
	
	void SetData(ubyte[30000] data) { data = this.data; }
	ubyte[30000] GetData() { return this.data; }
	
	uint GetIndex() { return this.code_ptr; }
	void  SetIndex(uint  new_index) { this.code_ptr = new_index; }

	uint GetDataPtr() { return this.data_ptr; }
	void SetDataPtr(uint new_datap) { this.data_ptr = new_datap; }
	
	bool Step()
	{
		if((code_ptr >= code.length) || !code)
			return false;
		
		switch(code[code_ptr].type)
		{
			case Parser.CommandType.Change:
			{
				code[code_ptr].arg %= (MaxValue + 1);
				
				if((data[data_ptr] + code[code_ptr].arg) > MaxValue)
				{
					data[data_ptr] = cast(ubyte)(data[data_ptr] + code[code_ptr].arg - MaxValue - 1);
				}
				else if((data[data_ptr] + code[code_ptr].arg) < MinValue)
				{
					data[data_ptr] = cast(ubyte)(data[data_ptr] + code[code_ptr].arg + MaxValue + 1);
				}
				else
					data[data_ptr]+=code[code_ptr].arg;
				
				if(code_ptr == 13)
					writeln(data[2]);
				
				++code_ptr;
			}
			break;
			
			case Parser.CommandType.Move:
			{
				code[code_ptr].arg %= (MaxData + 1);

				if((data_ptr + code[code_ptr].arg) > MaxData)
				{
					data_ptr = cast(uint)(data_ptr + code[code_ptr].arg - MaxData - 1);
				}
				else if((data_ptr + code[code_ptr].arg) < MinData)
				{
					data_ptr = cast(uint)(data_ptr + code[code_ptr].arg + MaxData + 1);
				}
				else
					data_ptr+=code[code_ptr].arg;
				
				++code_ptr;
			}
			break;
			
			case Parser.CommandType.LoopBegin:
			{
				if(data[data_ptr] == 0)
				{
 					code_ptr = code[code_ptr].arg;
				}
				else
					++code_ptr;
			}
			break;
			
			case Parser.CommandType.LoopEnd:
			{
				if(data[data_ptr] != 0)
				{
					code_ptr = code[code_ptr].arg;
				}
				else
					++code_ptr;
			}
			break;
			
			case Parser.CommandType.Input:
			{
				data[data_ptr] = cast(ubyte)getchar();
				
				++code_ptr;
			}
			break;
			
			case Parser.CommandType.Output:
			{
				putchar(cast(char)(data[data_ptr]));
				
				++code_ptr;
			}
			break;
			
			default: break;
		}
		
		return true;
	}
	
	bool Run()
	{
		if(!code)
			return false;
		
		while(Step()){}
		
		return true;
	}
	
private:
	uint code_ptr;
	uint data_ptr;

	Parser.Command[] code;
	ubyte[30000] data;
	
	const MaxValue = 255;
	const MinValue = 0;
	const MaxData = 29999;
	const MinData = 0;
}
