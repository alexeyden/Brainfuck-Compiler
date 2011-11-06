module Brainfuck.Compiler;

import Brainfuck.Parser;
import Brainfuck.Codegen;
import Brainfuck.FileFormat;

import std.stdio;

/* TODO: more verbose output */
class CompilerIntelELF32
{
	public:
		static bool Compile(string in_file,string out_file)
		{
			//Parse
			Parser bf_parser = new Parser();
			if(!bf_parser.SetSourceFromFile(in_file))
			{
				writeln("Can not read souce file: ",in_file);
				return false;
			}
			
			Parser.ParseError err;
			uint err_pos;
			err = bf_parser.Validate(err_pos);
			
			if(err != Parser.ParseError.None)
			{
				writeln("PARSER ERROR");
				
				if(err == Parser.ParseError.UnmatchedLeftBrace)
					writeln("Unmatched [ at ",err_pos);
				else if(err == Parser.ParseError.UnmatchedRightBrace)
					writeln("Unmatched ] at ",err_pos);
				
				return false;
			}
			
			Parser.Command[] code;
			code = bf_parser.Parse();
			
			//Generate x86 instructions
			CodeGenerator bf_codegen = new CodeGenerator(code);
			
			ubyte[] x86code;
			CodeGenerator.Relocation[] reloc;
			if(!bf_codegen.Generate(x86code,reloc))
			{
				writeln("CODE GENERATOR ERROR");
				
				return false;
			}
		
			//Save to ELF32 object file
			FileELF32Obj bf_file = new FileELF32Obj(x86code,reloc,in_file);
			if(!bf_file.Write(out_file))
			{
				writeln("Can not save to file: ",out_file);
				return false;
			}
			
			writeln("SUCCESS!");
			
			return true;
		}
}
