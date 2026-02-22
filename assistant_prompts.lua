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
        desc = _("Szybko wyjaśnia kim lub czym jest zaznaczony termin w kontekście książki."),
        system_prompt = "Jesteś asystentem literackim. Zawsze odpowiadaj w języku {language}. Bądź niezwykle zwięzły.",
        user_prompt = [[
Kim lub czym jest "{highlight}" w książce "{title}" autorstwa {author}? 

Odpowiedz w 1-3 krótkich zdaniach. Skup się wyłącznie na najważniejszych, konkretnych faktach i roli tej postaci/rzeczy w fabule na podstawie poniższego kontekstu. Nie pisz wstępów ani podsumowań.

Kontekst:
{context}
]],
    },
    dictionary = {
        order = -10,
        text = _("Dictionary"),
        desc = _("Krótki słownik dopasowany do kontekstu."),
    },
    quick_note = {
        order = 5,
        text = _("Quick Note"),
        desc = _("Szybka notatka."),
        user_prompt = "", 
    },
    idiom_check = {
        text = _("Sprawdź Idiom"),
        order = 15,
        desc = _("Sprawdza, czy zaznaczony tekst to idiom lub slang i wyjaśnia go po polsku."),
        user_prompt = [[
Czy zaznaczony fragment "{highlight}" to idiom, metafora, phrasal verb lub potoczne powiedzenie? 
Jeśli tak, podaj jego polski odpowiednik i krótko wyjaśnij znaczenie. Jeśli to zwykłe zdanie, po prostu je przetłumacz.
Odpowiedź musi być krótka i wyłącznie w języku: {language}.

Kontekst: {context}
]],
    },
    translate = {
        order = 30,
        text = _("Tłumacz"),
        desc = _("Profesjonalne, literackie tłumaczenie zaznaczonego tekstu."),
        user_prompt = [[
Jesteś profesjonalnym tłumaczem literatury. Przetłumacz poniższy fragment na język {language}. 
Zadbaj o to, aby tłumaczenie brzmiało naturalnie, oddawało oryginalny ton, styl i emocje autora. Pomiń dosłowne tłumaczenia idiomów na rzecz ich odpowiedników znaczeniowych.

Zwróć TYLKO przetłumaczony tekst, bez żadnych dodatkowych komentarzy.

[TEKST]:
{highlight}
]],
    },
    summarize = {
        text = _("Streszczenie"),
        order = 40,
        desc = _("Krótkie podsumowanie trudniejszego akapitu lub strony."),
        user_prompt = [[
Przeczytaj poniższy fragment i w 2-3 prostych zdaniach streść, co się w nim dzieje lub o czym mówi. 
Odpowiedz wyłącznie w języku: {language}.

Fragment: {highlight}]],
    },
    explain = {
        text = _("Wyjaśnij kontekst"),
        order = 80,
        desc = _("Szybkie wyjaśnienie o co chodzi w zaznaczonym fragmencie."),
        user_prompt = [[
Wyjaśnij krótko i w prostych słowach, jakie jest ukryte znaczenie lub główny sens tego fragmentu tekstu w oparciu o kontekst. 
Odpowiedz maksymalnie w 2-3 zdaniach, wyłącznie w języku: {language}.

Fragment: {highlight}
Kontekst: {context}
]],
    },
}

local assistant_prompts = {
    default = {
        system_prompt = "Jesteś pomocnym asystentem. Odpowiadaj krótko i w formacie Markdown.",
    },
    recap = {
        system_prompt = "Jesteś asystentem literackim. Odpowiadaj w formacie Markdown.",
        user_prompt = [[
Książka: '''{title}''' autorstwa '''{author}''' (przeczytano {progress}%).
Przypomnij krótko (w 3-4 zdaniach), co wydarzyło się do tej pory, aby pomóc mi wrócić do czytania. 
Nie zdradzaj spoilerów z dalszej części książki. Dopasuj ton do gatunku powieści.
Odpowiedz całkowicie w języku {language}.]]
    },
    xray = {
        system_prompt = "Jesteś asystentem literackim. Odpowiadaj w formacie Markdown.",
        user_prompt = [[
Wygeneruj krótki, bez-spoilerowy przewodnik (X-Ray) dla książki **{title}** ({author}) do momentu {progress}%.
Użyj języka: **{language}**.

### Główne Postacie
(Wymień 3-5 najważniejszych postaci i jednym zdaniem określ ich obecny status)

### Kluczowe Miejsca
(Wymień 2-3 obecne lokacje)

### Ostatnie wydarzenia
(Zapisz w 2-3 punktach najważniejsze rzeczy, które wydarzyły się ostatnio)
        ]],
    },    
    book_info = {
        system_prompt = "Jesteś ekspertem literackim. Odpowiadaj krótko, zwięźle i po polsku.",
        user_prompt = [[
Wygeneruj informacje o książce "{title}" autorstwa {author}:

### O książce
- Krótkie streszczenie (2-3 zdania), gatunek i rok wydania.

### O autorze
- Krótka biografia (1-2 zdania) i 2-3 inne znane dzieła.

### Kontekst
- Tło historyczne lub kulturowe powstania książki (1-2 zdania).

### Podobne książki
- 3 podobne książki z dobrymi ocenami. (Podaj tylko tytuł, autora i jedno zdanie o podobieństwie).

Odpowiedz wyłącznie w formacie Markdown i języku: {language}.]]
    },
    annotations = {
        system_prompt = "Jesteś asystentem analizującym notatki. Odpowiadaj zwięźle, konkretnie i po polsku.",
        user_prompt = [[
Przeanalizuj moje poniższe notatki i podkreślenia. Stwórz krótkie, uporządkowane podsumowanie:

### 1. Kluczowe wnioski
- 3 do 5 najważniejszych myśli, lekcji lub zwrotów akcji z tych notatek.

### 2. Akcje / Refleksje
- 2-3 praktyczne kroki (dla poradników/non-fiction) lub główne motywy do przemyślenia (dla beletrystyki).

### 3. Kontekst
- Podsumuj w 2 zdaniach, jak te podkreślenia łączą się z ogólnym tematem książki lub wskaż pytania, nad którymi warto się zastanowić.

Zacznij od jednego zdania podsumowania ogólnego. Bądź bardzo konkretny. Język: {language}.]]
    },
    summary_using_annotations = {
        system_prompt = "Jesteś skrupulatnym analitykiem literackim. Odpowiadaj po polsku w formacie Markdown.",
        user_prompt = [[
Stwórz ustrukturyzowane podsumowanie na podstawie dostarczonego tekstu oraz moich notatek. 
Wpleć moje podkreślenia naturalnie w treść podsumowania, zamiast tworzyć dla nich osobną sekcję.

ZASADY:
1. **TL;DR**: Zacznij od 2-3 zdań podsumowujących główny przekaz.
2. **Zintegrowane Podsumowanie**: Streść tekst logicznie. Gdy trafisz na podkreślenie, zacytuj je (**pogrubione**) i od razu wyjaśnij jego znaczenie w kontekście. Jeśli do podkreślenia dołączona jest moja notatka, wstaw ją tuż po wyjaśnieniu w *[kursywie i nawiasach]*.
3. **Kluczowe Wnioski**: Wypunktuj 5-8 najważniejszych myśli (tu też możesz używać **podkreśleń**).
4. **Praktyczne Lekcje**: Podaj 3-5 konkretnych, życiowych wniosków.
5. **Sprzeczności**: Jeśli moja notatka kłóci się z tekstem książki, oznacz ją znakiem ⚠️ i krótko wyjaśnij. Ignoruj notatki całkowicie niezwiązane z tekstem.

Pamiętaj, by nie kopiować całej książki – skup się na esencji i moich notatkach. Odpowiadaj wyłącznie w języku: {language}.]]
    },
    dict = {
        system_prompt = "Jesteś precyzyjnym słownikiem dwujęzycznym. Odpowiadaj krótko w formacie Markdown.",
        user_prompt = [[
Przeanalizuj poniższe słowo lub wyrażenie w oparciu o dostarczony kontekst. Zwróć wynik dokładnie w tym formacie:

- **Znaczenie**: (Krótkie wyjaśnienie w języku {language})
- **Tłumaczenie z kontekstem**: (Przetłumacz całe zdanie na język {language}, pogrubiając szukane słowo)
- **Synonimy**: (2-3 słowa bliskoznaczne w oryginale)
- **Forma podst.**: (Podaj formę podstawową, jeśli słowo jest odmienione)

[KONTEKST]:
{context}

[SŁOWO/WYRAŻENIE]:
{word}]]
    },
    suggestions_prompt = T([[
Na koniec zaproponuj 2 krótkie pytania w języku {language}, używając formatu list Markdown:

```

---

**%1**

* [Pytanie 1](#q:Pytanie 1)
* [Pytanie 2](#q:Pytanie 2)

```
]], "Może Cię zainteresować:"),
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
