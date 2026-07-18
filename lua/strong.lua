local function strongify(inlines)
    return pandoc.Strong(inlines)
end

local function match_chizinski(inlines, i)
    local a = inlines[i]
    local b = inlines[i + 1]
    local c = inlines[i + 2]
    local d = inlines[i + 3]
    local e = inlines[i + 4]

    if not (a and b and c) then
        return nil
    end

    if a.t == "Str" and a.text == "Chizinski," and b.t == "Space" and c.t == "Str" then
        if c.text == "C.J." or c.text == "CJ" or c.text == "C." or c.text == "C" then
            if (c.text == "C." or c.text == "C") and d and e and d.t == "Space" and e.t == "Str" and (e.text == "J." or e.text == "J") then
                return {len = 5, inlines = {a, b, c, d, e}}
            end
            return {len = 3, inlines = {a, b, c}}
        end
    end

    return nil
end

function Block(el)
    if el.t == "Para" or el.t == "Plain" then
        local i = 1
        while i <= #el.content do
            local match = match_chizinski(el.content, i)
            if match then
                el.content[i] = strongify(match.inlines)
                for _ = 2, match.len do
                    table.remove(el.content, i + 1)
                end
                i = i + 1
            else
                i = i + 1
            end
        end
    end
    return el
end
