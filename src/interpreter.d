module Brainfuck.Interpreter;
import Brainfuck.Parser;
import std.stdio;

/* TODO: compiler like class interface */
class Interpreter
{
public:
	this(){}
	this(Parser.Command[] code) { SetCode(code); }
	
	void SetCode(Parser.Command[] code) { this.code = code; }
	Parser.Command[] GetCode() { return code; }
	
	void SetData(ubyte[30000] data) { data = this.data; }
	ubyte[30000] GetData() { return this.data; }
	
	uint GetIndex() { return this.code_ptr; }
	void  SetIndex(uint  new_index) { this.code_ptr = new_index; }
	
	bool Step()
	{
		if(code_ptr >= code.length)
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