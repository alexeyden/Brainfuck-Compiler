module Brainfuck.Codegen;
import Brainfuck.Parser;

/* Code generator for Intel32 platform
 * 
 * Used registers:
 * 	eax - data pointer
 */
class CodeGenerator
{
public:
	this(){}
	this(Parser.Command[] code) { SetCode(code); }
	
	struct Relocation
	{
		uint offset;
		ubyte size;
	}
	
	void SetCode(Parser.Command[] code) { this.code = code; }
	Parser.Command[] GetCode() { return this.code; }
	
	bool Generate(out ubyte[] data,out Relocation[] relocations)
	{
		data ~= OpcodeTable[OpcodeType.CodeBeg].data;
		
		foreach(int index, Parser.Command cur_cmd; code)
		{
			switch(cur_cmd.type)
			{
				case Parser.CommandType.Change:
				{
					ubyte[] cur_opcode;
					
					if(cur_cmd.arg >= 0)
					{
						cur_opcode = OpcodeTable[OpcodeType.Add].data;
						cur_opcode[OpcodeTable[OpcodeType.Add].op_offset] = cast(ubyte)(cur_cmd.arg);
					}
					else
					{
						cur_opcode = OpcodeTable[OpcodeType.Sub].data;
						cur_opcode[OpcodeTable[OpcodeType.Sub].op_offset] = cast(ubyte)(-cur_cmd.arg);
					}
					
					data ~= cur_opcode;
					
					relocations ~= Relocation(GetByteOffset(index) + OpcodeTable[OpcodeType.Add].rel_offset,4);
				}
				break;
				case Parser.CommandType.Move:
				{
					ubyte[] cur_opcode;
					
					if(cur_cmd.arg >= 0)
					{
						cur_opcode = OpcodeTable[OpcodeType.Right].data;
						cur_opcode[OpcodeTable[OpcodeType.Right].op_offset] = cast(ubyte)cur_cmd.arg;
					}
					else
					{
						cur_opcode = OpcodeTable[OpcodeType.Left].data;
						cur_opcode[OpcodeTable[OpcodeType.Left].op_offset] = cast(ubyte)(-cur_cmd.arg);
					}
					
					data ~= cur_opcode;
				}
				break;
				case Parser.CommandType.LoopBegin:
				{
					ubyte[] cur_opcode;
					
					cur_opcode = OpcodeTable[OpcodeType.LoopBeg].data;
					//cur_opcode[OpcodeTable[OpcodeType.LoopBeg].op_offset] = cast(ubyte)(GetByteOffset(cur_cmd.arg)-GetByteOffset(index+1));
					
					int* op = cast(int*)(&cur_opcode[OpcodeTable[OpcodeType.LoopBeg].op_offset]);
					*op = GetByteOffset(cur_cmd.arg) - GetByteOffset(index+1);
					
					data ~= cur_opcode;
					
					relocations ~= Relocation(GetByteOffset(index) + OpcodeTable[OpcodeType.LoopBeg].rel_offset,4);
				}
				break;
				case Parser.CommandType.LoopEnd:
				{
					ubyte[] cur_opcode;
					
					cur_opcode = OpcodeTable[OpcodeType.LoopEnd].data;
					//cur_opcode[OpcodeTable[OpcodeType.LoopEnd].op_offset] = cast(ubyte)(GetByteOffset(cur_cmd.arg)-GetByteOffset(index+1));
					int* op = cast(int*)(&cur_opcode[OpcodeTable[OpcodeType.LoopEnd].op_offset]);
					*op = GetByteOffset(cur_cmd.arg)-GetByteOffset(index+1);
					
					data ~= cur_opcode;
					
					relocations ~= Relocation(GetByteOffset(index) + OpcodeTable[OpcodeType.LoopEnd].rel_offset,4);
				}
				break;
				case Parser.CommandType.Input:
				{
					ubyte[] cur_opcode;
					
					cur_opcode = OpcodeTable[OpcodeType.Input].data;
					
					data ~= cur_opcode;
					
					relocations ~= Relocation(GetByteOffset(index) + OpcodeTable[OpcodeType.Input].rel_offset,4);
				}
				break;
				case Parser.CommandType.Output:
				{
					ubyte[] cur_opcode;
					
					cur_opcode = OpcodeTable[OpcodeType.Output].data;
					
					data ~= cur_opcode;
					
					relocations ~= Relocation(GetByteOffset(index) + OpcodeTable[OpcodeType.Output].rel_offset,4);
				}
				break;
				default: break;
			}
		}
		
		data ~= OpcodeTable[OpcodeType.CodeEnd].data;
		
		/* TODO: checking of bounds and so on */
		return true;
	}	
	
private:
	
	enum OpcodeType
	{
		Add    = 0,
		Sub    = 1,
		Right  = 2,
		Left   = 3,
		LoopBeg = 4,
		LoopEnd = 5,
		Output  = 6,
		Input = 7,
		CodeBeg = 8,
		CodeEnd = 9
	}
	
	struct Opcode
	{
		OpcodeType type;
		uint rel_offset; uint rel_size;	//relocation
		uint op_offset;  uint op_size;  //operand
		ubyte[] data;
	}
	
	Opcode[] OpcodeTable= [ 
		{
			OpcodeType.Add,
			2, 4, 6, 1,
			/* addb $|OO|,|RO|(%eax) */
			[0x80,0x80,0x00,0x00,0x00,0x00,0x00]
		}, 
		{
			OpcodeType.Sub,
			2, 4, 6, 1,
			/* subb $|OO|,|RO|(%eax) */
			[0x80,0xA8,0x00,0x00,0x00,0x00,0x00]
		},
		{
			OpcodeType.Right,
			0, 0, 2, 1,
			/* addb $|OO|,%eax */
			[0x83,0xC0,0x00]
		},
		{
			OpcodeType.Left,
			0, 0, 2, 1,
			/* subb $|OO|,%eax */
			[0x83,0xE8,0x00]
		},
		{ /* TODO: use long version of je\jne */
			OpcodeType.LoopBeg,
			2, 4, 9, 4,
			/* cmpb $0x00,|RO|(%eax)
			 * je |OO|
			 */
			[0x80,0xB8,0x00,0x00,0x00,0x00,0x00,
			0x0f,0x84,0x00,0x00,0x00,0x00]
		},
		{
			OpcodeType.LoopEnd,
			2, 4, 9, 4,
			/* cmpb $0x00,|RO|(%eax)
			 * jne |OO|
			 */
			[0x80,0xB8,0x00,0x00,0x00,0x00,0x00,
			0x0f,0x85,0x00,0x00,0x00,0x00]
		}, 
		{
			OpcodeType.Output,
			7, 4, 0, 0,
			/* push %eax
			 * mov $0x1,%ebx
			 * mov $|RO|,%ecx
			 * add %eax,%ecx
			 * mov $0x01,%edx
			 * mov $0x04,%eax
			 * int $0x80
			 * pop %eax
			 */
			[0x50,                    
			0xBB,0x01,0x00,0x00,0x00,
			0xB9,0x00,0x00,0x00,0x00,
			0x01,0xc1,
			0xBA,0x01,0x00,0x00,0x00,
			0xB8,0x04,0x00,0x00,0x00,
			0xCD,0x80,
			0x58]
		},                  
		{
			OpcodeType.Input,
			7, 4, 0, 0,
			/* push %eax
			 * mov $0x01,%eax
			 * mov $0x00,%ebx
			 * mov $|RO|,%ecx
			 * add %eax,%ecx
			 * mov $0x01,%edx
			 * mov $0x03,%eax
			 * mov $0x1,%eax
			 * pop %eax
			 */
			[0x50,
			0xB8,0x01,0x00,0x00,0x00,
			0xBB,0x00,0x00,0x00,0x00,
			0xB9,0x00,0x00,0x00,0x00,
			0x01,0xC1,
			0xBA,0x01,0x00,0x00,0x00,
			0xB8,0x03,0x00,0x00,0x00,
			0xCD,0x80,
			0x58]
		},
		{
			OpcodeType.CodeBeg,
			0, 0, 0, 0,
			/* xor %eax,%eax */
			[0x31,0xC0]
		},
		{	
			OpcodeType.CodeEnd,
			0, 0, 0, 0,
			/* TODO: asm code here */
			[0xB8,0x01,0x00,0x00,0x00,0xBB,0x00,0x00,0x00,0x00,0xCD,0x80]
		}
	];
	
	uint GetByteOffset(uint idx)
	{
		uint offset = OpcodeTable[OpcodeType.CodeBeg].data.length;
		
		for(int i = 0; i < idx; i++)
		{
			switch(code[i].type)
			{
				case Parser.CommandType.Change:
					offset+=OpcodeTable[OpcodeType.Add].data.length;
					break;
				case Parser.CommandType.Move:
					offset+=OpcodeTable[OpcodeType.Left].data.length;
					break;
				case Parser.CommandType.LoopBegin:
					offset+=OpcodeTable[OpcodeType.LoopBeg].data.length;
					break;
				case Parser.CommandType.LoopEnd:
					offset+=OpcodeTable[OpcodeType.LoopEnd].data.length;
					break;
				case Parser.CommandType.Input:
					offset+=OpcodeTable[OpcodeType.Input].data.length;
					break;
				case Parser.CommandType.Output:
					offset+=OpcodeTable[OpcodeType.Output].data.length;
					break;
				default: break;
			}
		}
		
		return offset;
	}
	
	Parser.Command[] code;
}
