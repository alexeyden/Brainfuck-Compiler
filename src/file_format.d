module Brainfuck.FileFormat;
import Brainfuck.Parser;
import Brainfuck.Codegen;
import std.stdio;

class FileELF32Obj
{
public:
	this(in ubyte[] code,in CodeGenerator.Relocation[] reloc, string src_filename)
	{
		this.code = cast(ubyte[])code;
		
		//Header: IA-32, Relocatable
		header.e_ident[0] = ELFMAG0;
		header.e_ident[1] = ELFMAG1;
		header.e_ident[2] = ELFMAG2;
		header.e_ident[3] = ELFMAG3;
		header.e_ident[4] = ELFCLASS32;
		header.e_ident[5] = ELFDATA2LSB;
		header.e_ident[6] = EV_CURRENT;

		header.e_type = ET_REL;
		header.e_machine = EM_386;
		header.e_version = EV_CURRENT;

		header.e_ehsize = Elf32_Ehdr.sizeof;

		header.e_shoff = Elf32_Ehdr.sizeof;
		header.e_shentsize = Elf32_Shdr.sizeof;
		header.e_shnum = 7;

		header.e_shstrndx = 1;
	
		//Sections
		//.shstrtab
		sections[1].sh_name = 1;
		sections[1].sh_type = SHT_STRTAB;
		sections[1].sh_flags = SHN_UNDEF;
		sections[1].sh_addr = SHN_UNDEF;
		sections[1].sh_offset = header.e_ehsize + header.e_shentsize*header.e_shnum;
		sections[1].sh_size = shstrtab.length;
		sections[1].sh_link = SHN_UNDEF;
		sections[1].sh_info = 0;
		sections[1].sh_addralign = 1;
		sections[1].sh_entsize = 0;

		//.strtab
		strtab ~= cast(ubyte[])(src_filename.dup);
		
		sections[2].sh_name = 11;
		sections[2].sh_type = SHT_STRTAB;
		sections[2].sh_flags = SHN_UNDEF;
		sections[2].sh_addr = SHN_UNDEF;
		sections[2].sh_offset = sections[1].sh_offset + sections[1].sh_size;
		sections[2].sh_size = strtab.length; 
		sections[2].sh_link = SHN_UNDEF;
		sections[2].sh_info = 0;
		sections[2].sh_addralign = 1;
		sections[2].sh_entsize = 0;

		//.text
		sections[3].sh_name = 19;
		sections[3].sh_type = SHT_PROGBITS;
		sections[3].sh_flags = SHF_ALLOC | SHF_EXECINSTR;
		sections[3].sh_addr = SHN_UNDEF;
		sections[3].sh_offset = sections[2].sh_offset + sections[2].sh_size;
		sections[3].sh_size = code.length;
		sections[3].sh_link = SHN_UNDEF;
		sections[3].sh_info = 0;
		sections[3].sh_addralign = 16;
		sections[3].sh_entsize = 0;
		
		//.rel.text
		sections[4].sh_name = 25;
		sections[4].sh_type = SHT_REL;
		sections[4].sh_flags = SHN_UNDEF;
		sections[4].sh_addr = SHN_UNDEF;
		sections[4].sh_offset = sections[3].sh_offset + sections[3].sh_size;
		sections[4].sh_size = reloc.length*Elf32_Rel.sizeof;
		sections[4].sh_link = 6;
		sections[4].sh_info = 3; //.text
		sections[4].sh_addralign = 4;
		sections[4].sh_entsize = Elf32_Rel.sizeof;

		//.data
		sections[5].sh_name = 35;
		sections[5].sh_type = SHT_PROGBITS;
		sections[5].sh_flags = SHF_ALLOC | SHF_WRITE;
		sections[5].sh_addr = SHN_UNDEF;
		sections[5].sh_offset = sections[4].sh_offset + sections[4].sh_size;
		sections[5].sh_size = data.length;
		sections[5].sh_link = SHN_UNDEF;
		sections[5].sh_info = 0;
		sections[5].sh_addralign = 4;
		sections[5].sh_entsize = 0; 


		//.symtab
		sections[6].sh_name = 41;
		sections[6].sh_type = SHT_SYMTAB;
		sections[6].sh_flags = SHN_UNDEF;
		sections[6].sh_addr = SHN_UNDEF;
		sections[6].sh_offset = sections[5].sh_offset + sections[5].sh_size;
		sections[6].sh_size = Elf32_Sym.sizeof * symbols.length;
		sections[6].sh_link = 2; //.strtab 
		sections[6].sh_info = 5;
		sections[6].sh_addralign = 4;
		sections[6].sh_entsize = Elf32_Sym.sizeof;


		//Relocations
		foreach(CodeGenerator.Relocation r;reloc)
		{
			relocations ~= Elf32_Rel(r.offset,(2<<8) + R_386_32);
		}

		//Symbols
		symbols[1].st_name = 13; //source file
		symbols[1].st_value = 0;
		symbols[1].st_size = 0;
		symbols[1].st_info = ( STB_LOCAL << 4) + (STT_FILE & 0xf);
		symbols[1].st_other = 0;
		symbols[1].st_shndx = SHN_ABS;
		
		//data
		symbols[2].st_name = 8;
		symbols[2].st_value = 0;
		symbols[2].st_size = 0;
		symbols[2].st_info =  ( STB_LOCAL << 4) + (STT_NOTYPE & 0xf);
		symbols[2].st_other = 0;
		symbols[2].st_shndx = 5; //.data
		
		//section .text
		symbols[3].st_name = SHN_UNDEF;
		symbols[3].st_value = 0;
		symbols[3].st_size = 0;
		symbols[3].st_info = ( STB_LOCAL << 4) + (STT_SECTION & 0xf);
		symbols[3].st_other = 0;
		symbols[3].st_shndx = 3; //.text
		
		//section .data
		symbols[4].st_name = SHN_UNDEF;
		symbols[4].st_value = 0;
		symbols[4].st_size = 0;
		symbols[4].st_info = ( STB_LOCAL << 4) + (STT_SECTION & 0xf);
		symbols[4].st_other = 0;
		symbols[4].st_shndx = 5; //.data
		
		//_start
		symbols[5].st_name = 1; 
		symbols[5].st_value = 0;
		symbols[5].st_size = 0;
		symbols[5].st_info = ( STB_GLOBAL << 4) + (STT_NOTYPE & 0xf);
		symbols[5].st_other = 0;
		symbols[5].st_shndx = 3;  //.text
	}
	
	//ELF32 Header
	struct Elf32_Ehdr
	{
		ubyte e_ident[16];
		ushort e_type;
		ushort e_machine;
		uint e_version;
		uint e_entry;
		uint e_phoff;
		uint e_shoff;
		uint e_flags;
		ushort e_ehsize;
		ushort e_phentsize;
		ushort e_phnum;
		ushort e_shentsize;
		ushort e_shnum;
		ushort e_shstrndx;
	};
	
	const ET_REL = 1;
	const EM_386 = 3;
	const EV_CURRENT = 1;

	// ELF identification
	const ELFMAG0 = 0x7f;
	const ELFMAG1 = 'E';
	const ELFMAG2 = 'L';
	const ELFMAG3 = 'F';
	const ELFCLASS32 = 1;
	const ELFDATA2LSB = 1;
	
	// ELF Section header
	struct Elf32_Shdr
	{
		uint sh_name;
		uint sh_type;
		uint sh_flags;
		uint sh_addr;
		uint sh_offset;
		uint sh_size;
		uint sh_link;
		uint sh_info;
		uint sh_addralign;
		uint sh_entsize;
	};
	
	const SHN_UNDEF = 0;
	const SHN_ABS = 0xfff1;
	const SHN_COMMON = 0xfff2;

	const SHT_NULL = 0;
	const SHT_PROGBITS = 1;
	const SHT_SYMTAB = 2;
	const SHT_STRTAB = 3;
	const SHT_NOBITS = 8;
	const SHT_REL = 9;

	const SHF_WRITE = 0x1;
	const SHF_ALLOC = 0x2;
	const SHF_EXECINSTR = 0x4;
	
	//Symbol table
	struct Elf32_Sym
	{
		uint st_name;
		uint st_value;
		uint st_size;
		ubyte st_info;
		ubyte st_other;
		ushort st_shndx;
	};
	
	const STB_LOCAL = 0;
	const STB_GLOBAL = 1;

	const STT_NOTYPE = 0;
	const STT_OBJECT = 1;
	const STT_SECTION = 3;
	const STT_FUNC = 2;
	const STT_FILE = 4;
	
	//Relocation
	struct Elf32_Rel
	{
		uint r_offset;
		uint r_info;
	};
	
	const R_386_32 = 1;
	
	bool Write(string filename)
	{
		try
		{
			auto fh = File(filename,"w");

			//Write header
			fh.rawWrite!(Elf32_Ehdr)([header]);

			//Write sections table
			fh.rawWrite!(Elf32_Shdr)(sections);
			
			//Write .shstrtab
			fh.rawWrite!(ubyte)(shstrtab);
			
			//Write .strtab
			fh.rawWrite!(ubyte)(strtab);
			
			//Write .text
			fh.rawWrite!(ubyte)(code);
			
			//Write .rel.text
			fh.rawWrite!(Elf32_Rel)(relocations);
			
			//Write .data
			fh.rawWrite!(ubyte)(data);
			
			//Write .symtab
			fh.rawWrite!(Elf32_Sym)(symbols);
			
			fh.close();
		}
		catch(StdioException)
		{
			return false;
		}
		return true;
	}
	
	ubyte[] GetRawData()
	{
		ubyte[] raw_data;
		/*
		raw_data ~= cast(ubyte[])(header);
		raw_data ~= cast(ubyte[][])(sections);
		raw_data ~= cast(ubyte[])(shstrtab);
		raw_data ~= cast(ubyte[])(strtab);
		raw_data ~= code;
		raw_data ~= cast(ubyte[])(relocations);
		raw_data ~= data;
		raw_data ~= cast(ubyte[])(symbols);
		*/
		return raw_data;
	}
	
private:
	Elf32_Ehdr header;
	Elf32_Shdr[7] sections;
	Elf32_Rel[] relocations;
	Elf32_Sym[6] symbols;
	
	ubyte[] shstrtab = cast(ubyte[])"\0.shstrtab\0.strtab\0.text\0.rel.text\0.data\0.symtab\0";
	ubyte[] strtab = cast(ubyte[])"\0_start\0data\0";
	
	ubyte[] code;	
	/* TODO: changeable data size? */
	ubyte[30000] data;
}