function decorate_range(pos,len,ind)
   local es = editor.EndStyled
   editor:StartStyling(pos,INDICS_MASK)
   editor:SetStyling(len,INDIC0_MASK + ind)
   editor:SetStyling(2,31)
end

function highlight_word(txt,flags)
  if not flags then flags = 0 end
  local s,e = editor:findtext(txt,flags,0)
  while s do 
    decorate_range(s,e-s,128)
    s,e = editor:findtext(txt,flags,e+1)
  end

end

function inline_aspell(filename)
    spellh = io.popen('aspell list < '..filename)
    decorate_range(0,editor.Length,-1)
    for line in spellh:lines() do
        --print (line)
        highlight_word(line,SCFIND_WHOLEWORD)
    end
end
