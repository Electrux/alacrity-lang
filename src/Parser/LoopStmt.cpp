/*
	Copyright (c) 2019, Electrux
	All rights reserved.
	Using the BSD 3-Clause license for the project,
	main LICENSE file resides in project's root directory.

	Please read that file and understand the license terms
	before using or altering the project.
*/

#include <vector>
#include <string>
#include <optional>

#include "../../include/Errors.hpp"
#include "../../include/Core.hpp"
#include "../../include/IO.hpp"
#include "../../include/Lexer/Lexer.hpp"
#include "../../include/Parser/Stmt.hpp"
#include "../../include/Parser/BlockStmt.hpp"
#include "../../include/Parser/LoopStmt.hpp"

Parser::LoopStmt::LoopStmt( const std::vector< std::string > & args, const BlockStmt * block, const LoopType loop_type )
	: Stmt( LOOP ), m_args( args ), m_block( block ), m_loop_type( loop_type ) {}

Parser::LoopStmt::~LoopStmt()
{
	if( m_block != nullptr ) {
		delete m_block;
	}
}

Parser::LoopStmt * Parser::LoopStmt::Parse( const LexSymVec & tokens, size_t & loc, std::vector< std::string > parent_funcs, const LoopType loop_type )
{
	std::vector< std::string > loop_args;
	BlockStmt * loop_block = nullptr;
	std::string err;
	int err_line = tokens[ loc ]->GetLine(), err_col = tokens[ loc ]->GetCol();
	bool done = true;
	std::string tmpstr;
	++loc;
	if( loc >= tokens.size() || ( tokens[ loc ]->GetType() != Lex::SEPAR || tokens[ loc ]->GetDetailType() != Lex::PARENOP ) ) {
		if( loc >= tokens.size() ) {
			err = "Expected <Parenthesis open>, but found <EOF>";
		} else {
			err = "Expected <Parenthesis open>, but found " + tokens[ loc ]->GetData();
		}
		int tmp_loc = loc >= tokens.size() ? loc - 1 : loc;
		err_line = tokens[ tmp_loc ]->GetLine();
		err_col = tokens[ tmp_loc ]->GetCol();
		goto error;
	}
	// one more ++loc for moving ahead of parenthesis
	++loc;
	while( loc < tokens.size() && ( tokens[ loc ]->GetType() != Lex::SEPAR || tokens[ loc ]->GetDetailType() != Lex::PARENCL ) ) {
		done = false;
		err_line = tokens[ loc ]->GetLine();
		err_col = tokens[ loc ]->GetCol();
		if( tokens[ loc ]->GetType() == Lex::STR || tokens[ loc ]->GetType() == Lex::NUM ) {
			tmpstr = tokens[ loc ]->GetData();
			done = true;
			loop_args.push_back( tmpstr );
			tmpstr.clear();
		} else if( tokens[ loc ]->GetType() == Lex::SEPAR && tokens[ loc ]->GetDetailType() == Lex::COMMA ) {
			++loc;
			continue;
		} else {
			err = "Expected <identifier> or ',', but found: " + tokens[ loc ]->GetData();
			err_line = tokens[ loc ]->GetLine();
			err_col = tokens[ loc ]->GetCol();
			goto error;
		}
		++loc;
	}
	if( !done ) {
		err = "Unfinished function call parse! Unknown error (probably parameter related)!";
		goto error;
	}
	if( loop_type == FOR && loop_args.size() != 0 && ( loop_args.size() < 3 || loop_args.size() > 4 ) ) {
		err = "Expected 3 - 4 or 0 arguments in loop for, but found: " + std::to_string( loop_args.size() );
		goto error;
	}
	if( loop_type == FOREACH && loop_args.size() < 2 ) {
		err = "Expected at least 2 arguments in loop foreach, but found: " + std::to_string( loop_args.size() );
		goto error;
	}
	if( loop_type == FOREACHVAR && ( loop_args.size() != 2 && loop_args.size() != 3 ) ) {
		err = "Expected 2 - 3 arguments in loop foreach_var, but found: " + std::to_string( loop_args.size() );
		goto error;
	}
	if( loc + 1 >= tokens.size() ) {
		return new LoopStmt( loop_args, nullptr, loop_type );
	}
	if( tokens[ loc + 1 ]->GetType() == Lex::SEPAR && tokens[ loc + 1 ]->GetDetailType() == Lex::BRACEOP ) {
		++loc;
		err_line = tokens[ loc ]->GetLine();
		err_col = tokens[ loc ]->GetCol();
		auto block_var = BlockStmt::Parse( tokens, loc, parent_funcs );
		if( std::holds_alternative< int >( block_var ) ) {
			err = "Error encountered while parsing block from foreach call";
			goto error;
		} else {
			loop_block = BlockStmt::GenBlock( std::get< std::vector< Stmt * > >( block_var ) );
		}
	}
	return new LoopStmt( loop_args, loop_block, loop_type );
error:
	IO::out.IncTab( false );
	IO::out() << "Error: " << err << "; on line: " << err_line << "[" << err_col << "]\n";
	IO::out.DecTab();
	return nullptr;
}

void Parser::LoopStmt::Disp( const bool has_next ) const
{
	IO::out.IncTab( has_next );
	IO::out( has_next ) << " Loop at <" << this << ">:\n";
	IO::out.IncTab( true );

	if( m_loop_type == FOR ) IO::out( true ) << " type: for\n";
	else if( m_loop_type == FOREACH ) IO::out( true ) << " type: foreach\n";
	else if( m_loop_type == FOREACHVAR ) IO::out( true ) << " type: foreach_var\n";
	IO::out( true ) << " args:\n";

	IO::out.IncTab( true );
	for( size_t i = 0; i < m_args.size(); ++i ) {
		IO::out( i != m_args.size() - 1 ) << " \"" << m_args[ i ] << "\"\n";
	}
	IO::out.DecTab();

	IO::out.DecTab();
	IO::out.IncTab( false );
	if( m_block == nullptr ) {
		IO::out() << " block: NULL\n";
	} else {
		IO::out() << " block:\n";
		m_block->Disp( false );
	}

	IO::out.DecTab( 2 );
}

const std::vector< std::string > & Parser::LoopStmt::GetArgs() const { return m_args; }
const Parser::BlockStmt * Parser::LoopStmt::GetBlock() const { return m_block; }
Parser::LoopType Parser::LoopStmt::GetType() const { return m_loop_type; }