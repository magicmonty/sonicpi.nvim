local M = {}

local autoCompletionWordSeparators = '[%s,(){}]'

M.get_words = function(line)
  local words = {}
  local word = ''
  local isWord = false
  for i = 1, #line do
    local char = line:sub(i, i)
    if char:match('^=$') then
      words = {}
      word = ''
      isWord = false
    elseif not char:match(autoCompletionWordSeparators) then
      word = word .. char
      isWord = true
    else
      if isWord then
        table.insert(words, word)
        word = ''
        isWord = false
      end
    end
  end
  if isWord then
    table.insert(words, word)
  end
  return words
end

M.get_context = function(words)
  return {
    first_word = #words > 0 and words[1] or nil,
    last_word = #words > 0 and words[#words] or nil,
    second_to_last_word = #words > 1 and words[#words - 1] or nil,
    second_word = #words > 1 and words[2] or nil or nil,
  }
end

return M
