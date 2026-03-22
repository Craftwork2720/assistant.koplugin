local _ = require("assistant_gettext")
local T = require("ffi/util").template
-- preconfigured prompts for various tasks

-- Custom prompts for the AI
-- Available placeholder for user prompts:
-- {title}  : book title from metadata
-- {author} : book author from metadata
-- {highlight}  : selected texts
-- {language}   : the `response_language` variable defined above
-- {user_input} : user input from the input dialog
-- {progress}   : the progress percentage of the book
--
-- text: text to display on the button in the UI.
-- order: order of the button in the UI, higher number means later in the list.
-- show_on_main_popup: if true, the button will be shown in the main popup dialog.

-- prompts attributes can be overridden in the configuration file.
local custom_prompts = {
    term_xray = {
        text = _("Term X-Ray"),
        order = -20,
        desc = _("This prompt creates a structured system for generating context-aware definitions of words or phrases from literature by analyzing the highlighted term within its surrounding text to provide nuanced explanations that capture both literal meaning and contextual significance."),
        system_prompt = "Jesteś analitykiem literackim tworzącym zwięzłe, encyklopedyczne opisy elementów narracyjnych. Odpowiadaj wyłącznie w języku {language}. Używaj formatu Markdown i prostego języka w stylu Wikipedii. Opieraj się WYŁĄCZNIE na dostarczonym kontekście.",
        user_prompt = [[
Wyjaśnij pojęcie "{highlight}" z książki "{title}" autorstwa {author}.

Zasady:
- 180–220 słów.
- Zwięźle i rzeczowo.
- Opieraj się WYŁĄCZNIE na dostarczonym kontekście, bez wiedzy ogólnej.
- Bez wstępu i podsumowania.
- Krótkie akapity.
- Jeśli pojęcie pojawia się w kontekście wielokrotnie — uwzględnij ewolucję jego znaczenia.

Struktura:

### Czym jest
Krótka definicja na podstawie kontekstu.

### Rola w historii
Jak funkcjonuje w narracji i jakie ma znaczenie dla fabuły.

### Kluczowy szczegół
1–2 ważne obserwacje kontekstowe.

Kontekst:
{context}
]],
    },
    dictionary = {
        order = -10, -- negative number indicates a stub prompt
        text = _("Dictionary"),
        desc = _("This prompt acts as a dictionary for the highlighted text, to a word or phrase."),
        -- this prompt is a stub (will not shown in follow-up questions)
        -- it will be replaced by the actual prompt in the code below
    },
    quick_note = {
        order = 5, --should be visible on additional questions dialog
        text = _("Quick Note"),
        desc = _("This button creates a quick note with highlighted text."),
        user_prompt = "", --dummy prompt
        -- this prompt is a stub
    },
    translate = {
        order = 30,
        text = _("Translate"),
        desc = _("This prompt translates the highlighted text to another language."),
        user_prompt = [[
Translate the text into {language}.

- Keep meaning and tone.
- Sound natural.
- Output only translation.
- No notes unless absolutely necessary.

Text:
{highlight}
]],
    },
    summarize = {
        text = _("Summarize"),
        order = 40,
        desc = _("This prompt summarizes the highlighted text, capturing its main points and essential details."),
        user_prompt = [[
    Streść poniższy tekst po polsku.
    
    - Maksymalnie 5 zdań.
    - Tylko najważniejsza myśl i kluczowe szczegóły.
    - Bez powtórzeń i zbędnych słów.
    - Odpowiedź wyłącznie po polsku.
    
    Tekst:
    {highlight}]],
    },
    explain = {
        text = _("Explain"),
        order = 80,
        desc = _("This prompt explains the highlighted text in detail, ensuring clarity and understanding."),
        user_prompt = [[
Wyjaśnij poniższy fragment z książki "{title}" autorstwa {author}.

Zasady:
- 4–6 zdań.
- Wyjaśnij co autor miał na myśli.
- Krótko objaśnij trudne słowa lub pojęcia.
- Zacznij bezpośrednio od wyjaśnienia.
- Bez powtórzeń i zbędnych słów.
- Odpowiedź wyłącznie w języku {language}.

Tekst:
{highlight}
]],
    },
}


local assistant_prompts = {
    default = {
        system_prompt = "You are a helpful AI assistant. Always respond in Markdown format.",
    },
    recap = {
        system_prompt =
        "You are an expert literary assistant that provides accurate information about books. Always respond in Markdown format.",
        user_prompt = [[
Very briefly recap the story up to {progress}%.

- Focus on recent events.
- No spoilers beyond this point.
- Max 8–10 sentences.
- Use bold for names only.

Match tone of the book.
Respond in {language}.
]],
    },
    xray = {
       system_prompt = "Jesteś doświadczonym asystentem literackim dostarczającym dokładnych informacji o książkach. Odpowiadaj wyłącznie w języku {language}. Używaj formatu Markdown. Nie zdradzaj wydarzeń wykraczających poza aktualny postęp czytelnika.",
        user_prompt = [[
Stwórz X-Ray dla książki "{title}" autorstwa {author}.

Zasady:
- Tylko krótkie zdania.
- Bez zbędnych słów i powtórzeń.
- NIE zdradzaj wydarzeń po {progress}% książki.
- Odpowiedź wyłącznie w języku {language}.
- Zwróć tylko strukturę X-Ray, nic więcej.

Wymagana struktura (Markdown):

### Postacie
Wymień 4–6 kluczowych postaci.
- **Imię** — 1–2 krótkie zdania _<u>relacja</u>_

### Miejsca
Wymień 3–5 ważnych miejsc.
- **Miejsce** — 1 krótkie zdanie _<u>ważne wydarzenie</u>_

### Główne tematy
Wymień 3–5 tematów.
- **Temat** — 1 krótkie zdanie

### Kluczowe pojęcia
Wymień 3–5 ważnych pojęć lub terminów.
- **Pojęcie** — bardzo zwięzłe znaczenie

### Ostatnie punkty zwrotne
Wymień 5–8 ważnych wydarzeń.
- **Rozdział / Scena:** jedno krótkie zdanie

### Powrót do lektury
* **Gdzie skończyliśmy:** 1–2 krótkie zdania
* **Aktualny cel:** 1 zdanie
* **Otwarty konflikt:** 1 zdanie
* **Nastrój:** 1 zdanie

Książka: {title} autorstwa {author}
Postęp: {progress}%
]],
    },
    book_info = {
        system_prompt =
        "You are an expert literary assistant that provides accurate information about books. Always respond in Markdown format.",
        user_prompt = [[
Generate detailed information about the book "{title}" by {author}. Provide the information in the following sections:

### Book Information
- Provide a summary of the book's plot or main themes.
- Mention the genre, publication date, and any notable editions.
- Include the number of pages or chapters if known.

### About the Author
- Give a brief biography of {author}.
- Mention their other notable works.
- Discuss their writing style or influences.

### Historical Context
- Explain the historical or cultural context in which the book was written or set.
- Discuss how the book's themes relate to the time period.

### Similar Books Recommendation
- Recommend 3-5 similar books with the best ratings on goodreads.
- Provide a brief description of each recommended book, highlighting the similarities. (e.g., theme, style, genre).
- Output this part as list, not a table.

Ensure all information is accurate and based on known facts. Respond entirely in {language}.]],
    },
    dict = {
        system_prompt =
    "Jesteś literackim słownikiem wyjaśniającym słowa w kontekście książki. Zawsze odpowiadaj w języku {language}. Zawsze używaj poprawnego Markdown. Odpowiedzi mają być zwięzłe, konkretne i spójne.",

        user_prompt = [[
Wyjaśnij podświetlone słowo "{word}" z książki "{title}" autorstwa {author}, na podstawie dostarczonego kontekstu.

## Kontekst z książki
Zdania zawierające lub związane z "{word}":
{context}

## Zadanie

### Format odpowiedzi (OBOWIĄZKOWY)

- ZAWSZE rozpocznij od nagłówka:
  ### {word}

- ZAWSZE używaj poprawnego Markdown (nagłówki, listy, kursywa).

---

Jeśli język słowa "{word}" różni się od {language}:

- **Tłumaczenie**: krótkie, jednoznaczne tłumaczenie słowa "{word}" na {language}.

- **Synonimy**: maksymalnie 3 synonimy dopasowane do znaczenia w TYM kontekście.

- **W książce**:
  1. Znajdź zdanie zawierające "{word}" w kontekście.
  2. Wybierz krótki fragment (kilka słów przed i po "{word}").
  3. Przetłumacz CAŁY fragment na {language}.
  4. Fragment MUSI być w 100% w {language} — bez żadnych słów w języku oryginalnym.
  5. Słowo "{word}" również musi być przetłumaczone.

  Format:
  *"...przetłumaczony fragment..."*

---

Jeśli słowo "{word}" jest w języku {language}:

- **Synonimy**: maksymalnie 3 synonimy dopasowane do kontekstu.

- **Kontekst**: krótkie, precyzyjne wyjaśnienie znaczenia słowa w TYM kontekście.
  Jeśli użycie jest symboliczne, archaiczne, metaforyczne lub gatunkowe — zaznacz to krótko.

---

## Ważne zasady (KRYTYCZNE)

- NIE pokazuj oryginalnego zdania w sekcji „W książce”.
- NIE mieszaj języków — cała odpowiedź musi być w {language}.
- NIE pokazuj najpierw oryginału, a potem tłumaczenia.
- ZAWSZE tłumacz całe wyrażenie, nie tylko jego część.
- Zachowuj spójny, czysty Markdown.
- NIE dodawaj żadnych dodatkowych komentarzy ani wstępu.

Pokaż tylko nagłówek i wymagane sekcje.
]],
    },

    suggestions_prompt = T([[
At the end of your response, first generate 2-3 questions in {language} language based on your answer. Critically, these questions **must not contain any quotation marks and parentheses, or any other punctuation whatsoever**. Only use letters and spaces.
Then, display these questions as hyperlinks in a **Markdown unordered list** using the following exact format:
```
---
__%1__

- [Question 1](#q:Question 1)
- [Question 2](#q:Question 2)
```
]], _("You may find these topics interesting:")),
}


local function table_merge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = table_merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end


local function table_sort(t, key)
    table.sort(t, function(a, b)
        if a[key] == nil or b[key] == nil then
            return false
        end
        return a[key] < b[key]
    end)
end


local M = {
    custom_prompts = custom_prompts,       -- Custom prompts for the AI
    assistant_prompts = assistant_prompts, -- Preconfigured prompts for the AI
    merged_prompts = nil,                  -- Merged prompts from custom and configuration
    sorted_custom_prompts = nil,           -- Sorted custom prompts
    show_on_main_popup_prompts = nil,      -- Prompts that should be shown on the main popup
}

-- Func description:
-- This function returns the merged custom prompts from the configuration and custom prompts.
-- It merges the custom prompts with the configuration prompts, if available.
-- return table of merged prompts
-- Example: { translate = { text = "Translate", user_prompt = "...", order = 1, show_on_main_popup = true }, ... }
M.getMergedCustomPrompts = function(conf_prompts)
    if M.merged_prompts then
        return M.merged_prompts
    end

    -- Merge custom prompts with configuration prompts
    if conf_prompts then
        M.merged_prompts = table_merge(custom_prompts, conf_prompts)
    else
        M.merged_prompts = custom_prompts
    end

    return M.merged_prompts
end

-- Func description:
-- This function returns a list of custom prompts sorted by their order.
-- filter_func: optional function to filter prompts, if it returns false, the prompt will be skipped.
-- return list item: {idx, order, text}
M.getSortedCustomPrompts = function(filter_func)
    if M.sorted_custom_prompts then
        return M.sorted_custom_prompts
    end

    -- Sort the merged prompts by order
    local sorted_prompts = {}
    for prompt_index, prompt in pairs(M.merged_prompts or custom_prompts) do
        -- Only add the prompt if there is no filter, or if the filter function returns true.
        if not filter_func or filter_func(prompt, prompt_index) == true then
            table.insert(sorted_prompts,
                {
                    idx = prompt_index,
                    order = prompt.order or 1000,
                    text = prompt.text or prompt_index,
                    desc = prompt
                        .desc or ""
                })
        end
    end
    table_sort(sorted_prompts, "order")

    return sorted_prompts
end

return M
