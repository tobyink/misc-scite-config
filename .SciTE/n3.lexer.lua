-- -*- coding: utf-8 -*-

function OnStyle(styler)
	S_DEFAULT = 0
	S_PUNC = 1
	S_KEYWORD = 2
	S_COMMENT = 3
	S_ISOF = 4
	S_SPARQL = 8
	S_URI = 10
	S_CURIE = 20
	S_BNODE = 21
	S_RDFTYPE = 22
	S_VARIABLE = 24
	S_LITERAL = 25
	S_LONGLITERAL = 26
	S_LANG = 27
	S_NUM = 28
	S_BOOL = 29
	S_INVALID = 9
	
	identifierCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_:"
	identifierStartCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_:$?"
	langCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_@"
	numericCharacters = "0123456789.eE"
	numericStartCharacters = "0123456789+-"
	sparqlWords = ' SELECT DISTINCT REDUCED FROM WHERE GRAPH UNION FILTER BASE PREFIX CONSTRUCT DESCRIBE ASK NAMED GROUP BY ASC DESC LIMIT OFFSET BINDINGS WITH INSERT DELETE DATA DROP CREATE SILENT MODIFY USING LOAD INTO CLEAR DEFAULT OPTIONAL SERVICE STR LANG LAMGMATCHES DATATYPE BOUND IRI URI BNODE COALESCE IF STRLANG STRDT SAMETERM ISIRI ISURI ISBLANK ISLITERAL REGEX EXISTS NOT COUNT SUM MIN MAX AVG SAMPLE GROUP_CONCAT SEPARATOR UNSAID '

	styler:StartStyling(styler.startPos, styler.lengthDoc, styler.initStyle)
	while styler:More() do

		-- Exit state if needed
		if styler:State() == S_CURIE then
			if not identifierCharacters:find(styler:Current(), 1, true) then
				identifier = styler:Token()
				if identifier:sub(1,2) == "_:" then
					styler:ChangeState(S_BNODE)
				elseif identifier:sub(1,1) == "?" then
					styler:ChangeState(S_VARIABLE)
				elseif identifier:sub(1,1) == "$" then
					styler:ChangeState(S_VARIABLE)
				elseif identifier:lower() == "a" then
					styler:ChangeState(S_RDFTYPE)
				elseif identifier:lower() == "is" then
					styler:ChangeState(S_ISOF)
				elseif identifier:lower() == "of" then
					styler:ChangeState(S_ISOF)
				elseif identifier:lower() == "true" or identifier:lower() == "false" then
					styler:ChangeState(S_BOOL)
				elseif sparqlWords:find(" "..identifier:upper().." ") then
					styler:ChangeState(S_SPARQL)
				elseif not identifier:find(":") then
					styler:ChangeState(S_INVALID)
				end
				styler:SetState(S_DEFAULT)
			end
		elseif styler:State() == S_NUM then
			if not numericCharacters:find(styler:Current(), 1, true) then
				styler:SetState(S_DEFAULT)
			end
		elseif styler:State() == S_KEYWORD then
			if not identifierCharacters:find(styler:Current(), 1, true) then
				styler:SetState(S_DEFAULT)
			end
		elseif styler:State() == S_COMMENT then
			if styler:Match("\n") or styler:Match("\r") then
				styler:SetState(S_DEFAULT)
			end
		elseif styler:State() == S_LANG then
			if not langCharacters:find(styler:Current(), 1, true) then
				styler:SetState(S_DEFAULT)
			end
		elseif styler:State() == S_URI then
			if styler:Match(">") then
				styler:ForwardSetState(S_DEFAULT)
			elseif styler:Token() == "<=" then
				styler:ChangeState(S_DEFAULT)
				styler:ForwardSetState(S_DEFAULT)
			end
		elseif styler:State() == S_LITERAL then
			literal = styler:Token()
			if styler:Match("\\\\") or styler:Match("\\\"") or styler:Match("\\\'") then
				styler:Forward()
				styler:Forward()
			elseif styler:Match( literal:sub(1,1) ) then
				styler:ForwardSetState(S_DEFAULT)
			end
		elseif styler:State() == S_LONGLITERAL then
			if styler:Match( styler:Token():sub(1,3) ) then
				styler:Forward()
				styler:Forward()
				styler:ForwardSetState(S_DEFAULT)
			end
		elseif styler:State() == S_PUNC then
			if styler:Match(".") or styler:Match(";") or styler:Match(",") or styler:Match("\[") or styler:Match("]") or styler:Match("(") or styler:Match(")") or styler:Match("^") then
				styler:SetState(S_PUNC)
			else
				styler:SetState(S_DEFAULT)
			end
		end

		-- Enter state if needed
		if styler:State() == S_DEFAULT then
			if styler:Match("<") then
				styler:SetState(S_URI)
			elseif styler:Match("@prefix") or styler:Match("@base") or styler:Match("@keywords") or styler:Match("@forSome") or styler:Match("@forAll") then
				styler:SetState(S_KEYWORD)
			elseif styler:Match("@") then -- and not (styler:Match("@prefix") or styler:Match("@base") or styler:Match("@keywords")) or styler:Match("@forSome") or styler:Match("@forAll") then
				styler:SetState(S_LANG)
			elseif styler:Match('"""') or styler:Match("'''") then
				styler:SetState(S_LONGLITERAL)
				styler:Forward()
				styler:Forward()
			elseif styler:Match("'") or styler:Match('"') then
				styler:SetState(S_LITERAL)
			elseif styler:Match(".") or styler:Match(";") or styler:Match(",") or styler:Match("\[") or styler:Match("]") or styler:Match("(") or styler:Match(")") or styler:Match("^") then
				styler:SetState(S_PUNC)
			elseif numericStartCharacters:find(styler:Current(), 1, true) then
				styler:SetState(S_NUM)
			elseif identifierStartCharacters:find(styler:Current(), 1, true) then
				styler:SetState(S_CURIE)
			elseif styler:Match("#") then
				styler:SetState(S_COMMENT)
			end
		end

		styler:Forward()
	end
	styler:EndStyling()
end
