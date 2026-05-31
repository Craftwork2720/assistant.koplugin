local _ = require("assistant_gettext")
local T = require("ffi/util").template

local custom_prompts = {
    term_xray = {
        text = _("Term X-Ray"),
        order = -20,
        desc = _(
            "Context-aware recall of characters, places and terms from the book."),
        system_prompt =
        "You are a reading assistant for e-book users (KOReader/Kindle). Focus ONLY on the highlighted term and provided context. Do NOT use external knowledge. Keep answers short, clear, and optimized for e-ink. Respond ONLY in {language}.",
        user_prompt = [[
## Zadanie

Wyjaśnij, czym jest "{highlight}" w kontekście książki.

## Zasady
- TYLKO na podstawie kontekstu
- Bez zgadywania
- Krótko i konkretnie

## Odpowiedź

### {highlight}

**Kim / czym jest:**  
1–2 zdania

**Rola / znaczenie:**  
Jeśli wynika z tekstu

**Kluczowe informacje:**  
- fakt 1  
- fakt 2  
- fakt 3  

**Uwagi:**  
Jeśli brak danych lub kontekst niepełny

## Kontekst
{context}
]],
    },

    dictionary = {
        order = -10,
        text = _("Dictionary"),
        desc = _("Dictionary lookup"),
    },

    quick_note = {
        order = 5,
        text = _("Quick Note"),
        desc = _("Quick note"),
        user_prompt = "",
    },

    translate = {
        order = 30,
        text = _("Translate"),
        desc = _("Translate text"),
        user_prompt = [[
Translate to {language}.

Rules:
- Output ONLY translation
- No comments
- No formatting

{highlight}
]],
    },

    summarize = {
        text = _("Summarize"),
        order = 40,
        desc = _("Summarize text"),
        user_prompt = [[
Streszcz tekst krótko i jasno.

Zasady:
- Krótkie akapity
- Tylko najważniejsze informacje
- Bez lania wody

{highlight}
]],
    },

    simplify = {
        text = _("Simplify"),
        order = 50,
        desc = _("Simplify text"),
        user_prompt =
        [[Uprość tekst bez zmiany znaczenia.

Zasady:
- Prosty język
- Krótkie zdania
- Zachowaj sens

{highlight}]],
    },

    explain = {
        text = _("Explain"),
        order = 80,
        desc = _("Explain text"),
        user_prompt = [[
Wyjaśnij tekst jasno i prosto.

Zasady:
- Odpowiedź po {language}
- Krótko i czytelnie
- Bez zbędnych detali

{highlight}]],
    },
    wikipedia = {
        text = _("Wikipedia"),
        order = 100,
        desc = _(
            "This prompt generates a comprehensive Wikipedia-style article based on the highlighted text, ensuring factual accuracy and neutrality."),
        user_prompt =
[[You are an objective, encyclopedic Informative Assistant in the style of Wikipedia.

**Task:**

* When given a topic, generate a factual, neutral, and comprehensive article.
* Begin with a concise introduction summarizing the topic.
* Cover key aspects: history, concepts, applications, notable events, or impacts.
* Maintain Wikipedia’s tone and structure throughout.

**Research instructions:**

* If your knowledge may be incomplete or outdated, **prioritize retrieving information from web search** to ensure accuracy.
* Verify facts with reputable sources; avoid speculation or unverifiable claims.

**Output:**

* Provide structured, clear, and coherent content.
* Deliver entirely in {language}.

Topic to cover (from user selection): {highlight}]],
    },
}

local assistant_prompts = {
    default = {
        system_prompt = [[
Jesteś asystentem czytelnika e-booków (KOReader/Kindle).

Zasady:
- Maksymalna czytelność
- Krótkie odpowiedzi
- Zero zbędnych informacji

Format:
- Markdown
- Krótkie akapity

Język:
- ZAWSZE {language}
- NIGDY inny język
]],
    },

    recap = {
        system_prompt =
        "You are a reading assistant. Summarize previous content without spoilers. Respond ONLY in {language}.",
        user_prompt = [[
Książka: "{title}" – {progress}%

Stwórz krótkie przypomnienie ostatnich wydarzeń:
- bez spoilerów
- skup się na ostatnich fragmentach

Format:
- 1 krótki akapit
- 3–5 punktów

]],
    },

    xray = {
        system_prompt =
        "You are a reading assistant. Provide structured recall info. Respond ONLY in {language}.",
        user_prompt = [[
Stwórz przegląd do aktualnego momentu książki.

### Postacie
- imię — 1 zdanie kim jest

### Miejsca
- nazwa — 1 zdanie

### Motywy
- motyw — krótko

### Kluczowe wydarzenia
- punkt 1
- punkt 2

Bez spoilerów. Krótko i czytelnie.
]],
    },

    book_info = {
        system_prompt = “Jesteś ekspertem literackim. Odpowiadaj krótko, zwięźle i po polsku.”,
        user_prompt = [[
Wygeneruj informacje o książce “{title}” autorstwa {author}:

### O książce
- Krótkie streszczenie (2-3 zdania), gatunek i rok wydania.

### O autorze
- Krótka biografia (1-2 zdania) i 2-3 inne znane dzieła.

### Kontekst
- Tło historyczne lub kulturowe powstania książki (1-2 zdania).

### Podobne książki
- 3 podobne książki z dobrymi ocenami. (Podaj tylko tytuł, autora i jedno zdanie o podobieństwie).

Odpowiedz wyłącznie w formacie Markdown i języku: {language}.]],
    },

    annotations = {
        system_prompt =
        "You are a reading assistant. Analyze notes. Respond ONLY in {language}.",
        user_prompt = [[
Na podstawie notatek:

### Najważniejsze
- punkt 1
- punkt 2

### Wnioski
- punkt 1
- punkt 2

### Do przemyślenia
- punkt 1
]],
    },

    summary_using_annotations = {
        system_prompt =
        "You are a reading assistant. Summarize with highlights. Respond ONLY in {language}.",
        user_prompt = [[
Streszczenie książki z uwzględnieniem zaznaczeń.

Zasady:
- wplataj **highlighty**
- krótko i czytelnie

Struktura:
- TLDR
- Streszczenie
- Najważniejsze punkty
]],
    },

    dict = {
    system_prompt =
    "You are a precise dictionary assistant for e-book readers. You MUST use the provided context to determine meaning. Do NOT guess or use generic definitions. Always respond in Markdown and ONLY in {language}.",
    user_prompt = T([[
Explain the word "{word}" as used in the book.

Context (fragment of the book, includes surrounding text):
{context}

### {word}

**%1**  
Znaczenie słowa W TYM KONTEKŚCIE (nie ogólne).

**%2**  
Naturalne tłumaczenie zdania z kontekstu.  
Zachowaj styl książki i wyróżnij **przetłumaczone słowo**.

**%3**
- synonim pasujący do tego kontekstu
- synonim pasujący do tego kontekstu

Rules:
- Kontekst jest najważniejszy (priorytet)
- NIE podawaj ogólnej definicji jeśli kontekst wskazuje coś innego
- Jeśli kontekst jest niejednoznaczny — zaznacz to
- Krótko i czytelnie
]],
        _("Znaczenie"),
        _("Tłumaczenie"),
        _("Synonimy"))
},


    dict_en_pl = {
    system_prompt =
    "You are a precise English-Polish dictionary assistant. You MUST rely on the provided context from the book. Do NOT use generic meanings if context suggests otherwise. Respond ONLY in Polish.",
    user_prompt = [[
Explain the English word "{word}" based on the book context.

Context (fragment książki z otoczeniem słowa):
{context}

### {word}

**Znaczenie:**  
Znaczenie w tym konkretnym fragmencie. Jeśli słowo jest częścią frazy (phrasal verb, idiom, fixed expression), podaj znaczenie **całej frazy**, a nie tylko samego słowa.

**Tłumaczenie:**  
(Najlepsze tłumaczenie w tym kontekście, jeśli to fraza – tłumaczenie całej frazy)
**→ tłumaczenie**

**Zdanie:**  
(Pełne tłumaczenie zdania)
(zachowaj styl książki i wyróżnij **słowo** lub **całą frazę**, jeśli słowo jest jej częścią)

Rules:
- Najpierw analizuj kontekst, dopiero potem tłumacz
- Jeśli słowo jest częścią frazy, podaj znaczenie całej frazy
- Tłumaczenie musi pasować do zdania, nie tylko do słowa
- Unikaj „słownikowych” oderwanych tłumaczeń
- Krótko i bardzo czytelnie
]],
},


    dict_pl = {
    system_prompt =
    "You are a precise Polish dictionary assistant. You MUST interpret meaning based on the provided book context. Respond ONLY in Polish.",
    user_prompt = [[
Wyjaśnij słowo "{word}" na podstawie kontekstu z książki.

Kontekst:
{context}

### {word}

**Znaczenie:**  
Znaczenie w tym konkretnym użyciu (nie ogólne).

**Synonimy:**
- synonim pasujący do kontekstu
- synonim pasujący do kontekstu
- synonim pasujący do kontekstu

Zasady:
- Kontekst jest kluczowy
- Jeśli znaczenie odbiega od typowego — zaznacz to
- Jeśli kontekst jest niejasny — napisz to
- Krótko i czytelnie
]],
},


    suggestions_prompt = T([[
Na końcu dodaj 2 krótkie pytania po {language} bez znaków specjalnych.

---
__%1__

- [Pytanie 1](#q:Pytanie 1)
- [Pytanie 2](#q:Pytanie 2)
]], _("Powiązane tematy:")),
}

local function table_merge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do result[k] = v end
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
        return (a[key] or 1000) < (b[key] or 1000)
    end)
end

local M = {
    custom_prompts = custom_prompts,
    assistant_prompts = assistant_prompts,
    merged_prompts = nil,
    sorted_custom_prompts = nil,
    show_on_main_popup_prompts = nil,
}

M.getMergedCustomPrompts = function(conf_prompts)
    if M.merged_prompts then return M.merged_prompts end
    if conf_prompts then
        M.merged_prompts = table_merge(custom_prompts, conf_prompts)
    else
        M.merged_prompts = custom_prompts
    end
    return M.merged_prompts
end

M.getSortedCustomPrompts = function(filter_func)
    local sorted_prompts = {}
    for prompt_index, prompt in pairs(M.merged_prompts or custom_prompts) do
        if not filter_func or filter_func(prompt, prompt_index) == true then
            table.insert(sorted_prompts, {
                idx = prompt_index,
                order = prompt.order or 1000,
                text = prompt.text or prompt_index,
                desc = prompt.desc or ""
            })
        end
    end
    table_sort(sorted_prompts, "order")
    return sorted_prompts
end

return M
