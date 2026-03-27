local _ = require("assistant_gettext")
local T = require("ffi/util").template

-- =============================================================================
-- CUSTOM PROMPTS — prompty wywoływane przez zaznaczenie tekstu
-- =============================================================================
-- Dostępne zmienne:
--   {title}      — tytuł książki z metadanych
--   {author}     — autor książki z metadanych
--   {highlight}  — zaznaczony tekst
--   {language}   — język odpowiedzi (zmienna response_language)
--   {user_input} — tekst wpisany przez użytkownika
--   {progress}   — procent ukończenia książki
--   {context}    — szerszy fragment tekstu wokół zaznaczenia
-- =============================================================================

local custom_prompts = {

    -- -------------------------------------------------------------------------
    -- TERM X-RAY — encyklopedyczne wyjaśnienie pojęcia w kontekście narracji
    -- -------------------------------------------------------------------------
    term_xray = {
        text = _("Term X-Ray"),
        order = -20,
        desc = _("Generates a concise, encyclopedic explanation of a highlighted term or phrase — grounded strictly in the surrounding narrative context."),
        system_prompt = [[
Jesteś analitykiem literackim. Piszesz zwięzłe, encyklopedyczne noty w stylu Wikipedii.
Zasady:
- Odpowiadaj WYŁĄCZNIE w języku {language}.
- Używaj Markdown (nagłówki ###, pogrubienia, listy).
- Opieraj się WYŁĄCZNIE na dostarczonym kontekście — bez wiedzy ogólnej.
- Nie pisz wstępu ani podsumowania.]],
        user_prompt = [[
Wyjaśnij pojęcie **"{highlight}"** z książki *{title}* ({author}).

### Czym jest
Definicja pojęcia na podstawie kontekstu. (2–3 zdania)

### Rola w narracji
Jak funkcjonuje w fabule i co wnosi do historii. (2–3 zdania)

### Kluczowy szczegół
Najważniejsza obserwacja kontekstowa — np. symbolika, ewolucja znaczenia, ironia. (1–2 zdania)

---
Kontekst:
{context}
]],
    },

    -- -------------------------------------------------------------------------
    -- QUICK NOTE — szybka notatka do zaznaczonego fragmentu
    -- -------------------------------------------------------------------------
    quick_note = {
        order = 5,
        text = _("Quick Note"),
        desc = _("Creates a quick personal note attached to the highlighted passage."),
        user_prompt = "",
    },

    -- -------------------------------------------------------------------------
    -- TRANSLATE — tłumaczenie zaznaczonego tekstu
    -- -------------------------------------------------------------------------
    translate = {
        order = 30,
        text = _("Translate"),
        desc = _("Translates the highlighted text into the configured response language, preserving meaning and tone."),
        user_prompt = [[
Przetłumacz poniższy tekst na {language}.

Zasady:
- Zachowaj znaczenie i ton oryginału.
- Brzmij naturalnie w języku docelowym.
- Zwróć TYLKO tłumaczenie — bez komentarzy.

Tekst:
{highlight}
]],
    },

    -- -------------------------------------------------------------------------
    -- SUMMARIZE — streszczenie zaznaczonego fragmentu
    -- -------------------------------------------------------------------------
    summarize = {
        text = _("Summarize"),
        order = 40,
        desc = _("Summarizes the highlighted passage in 3–5 sentences, capturing only the essential meaning."),
        user_prompt = [[
Streść poniższy fragment w języku {language}.

Zasady:
- Maks. 5 zdań.
- Tylko najważniejsza myśl i kluczowe szczegóły.
- Bez powtórzeń i zbędnych słów.
- Zacznij bezpośrednio od streszczenia.

Tekst:
{highlight}
]],
    },

    -- -------------------------------------------------------------------------
    -- EXPLAIN — wyjaśnienie trudnego fragmentu
    -- -------------------------------------------------------------------------
    explain = {
        text = _("Explain"),
        order = 80,
        desc = _("Explains what the author meant in the highlighted passage — clarifies difficult words, metaphors, and implicit meaning."),
        user_prompt = [[
Wyjaśnij poniższy fragment z książki *{title}* ({author}).

Zasady:
- 4–6 zdań.
- Co autor miał na myśli? Jaki jest sens tego fragmentu?
- Krótko objaśnij trudne słowa, metafory lub aluzje.
- Zacznij bezpośrednio od wyjaśnienia — bez wstępu.
- Odpowiedź w języku {language}.

Fragment:
{highlight}
]],
    },

    -- -------------------------------------------------------------------------
    -- WIKIPEDIA — encyklopedyczny artykuł o zaznaczonym pojęciu
    -- -------------------------------------------------------------------------
    wikipedia = {
        text = _("Wikipedia"),
        order = 100,
        desc = _("Generates a concise Wikipedia-style article about the highlighted term or topic — factual, neutral, structured."),
        user_prompt = [[
Napisz zwięzły artykuł encyklopedyczny w stylu Wikipedii na temat: **{highlight}**.

Zasady:
- Zacznij od krótkiego akapitu definiującego temat (2–3 zdania).
- Przedstaw najważniejsze fakty, kontekst historyczny lub naukowy, kluczowe zastosowania.
- Neutralny, rzeczowy ton — bez opinii.
- Używaj nagłówków (###) dla sekcji tematycznych.
- Maks. 300–400 słów.
- Odpowiedź w języku {language}.
]],
    },
}


-- =============================================================================
-- ASSISTANT PROMPTS — prompty systemowe i złożone funkcje asystenta
-- =============================================================================

local assistant_prompts = {

    -- -------------------------------------------------------------------------
    -- DEFAULT — domyślny prompt systemowy
    -- -------------------------------------------------------------------------
    default = {
        system_prompt = [[
Jesteś pomocnym asystentem czytelnika. Odpowiadaj zwięźle i rzeczowo.
Zawsze używaj Markdown. Odpowiadaj w języku {language}.]],
    },

    -- -------------------------------------------------------------------------
    -- RECAP — krótkie przypomnienie fabuły do bieżącego miejsca
    -- -------------------------------------------------------------------------
    recap = {
        system_prompt = [[
Jesteś asystentem literackim. Odpowiadaj zwięźle, używaj Markdown.
NIE zdradzaj wydarzeń po bieżącym miejscu w książce.]],
        user_prompt = [[
Przypomnij mi w skrócie fabułę książki *{title}* ({author}) do miejsca, w którym jestem ({progress}%).

Zasady:
- Maks. 8–10 zdań.
- Skup się na ostatnich wydarzeniach i otwartych wątkach.
- Bez spoilerów za {progress}%.
- **Pogrub** tylko imiona postaci.
- Dopasuj ton do klimatu książki.
- Odpowiedź w {language}.
]],
    },

    -- -------------------------------------------------------------------------
    -- XRAY — strukturalny przegląd książki: postacie, miejsca, tematy
    -- -------------------------------------------------------------------------
    xray = {
        system_prompt = [[
Jesteś asystentem literackim tworzącym strukturalne zestawienia książek.
Odpowiadaj WYŁĄCZNIE w języku {language}. Używaj Markdown.
NIE zdradzaj wydarzeń po wskazanym miejscu w książce.]],
        user_prompt = [[
Stwórz X-Ray dla książki *{title}* ({author}) do {progress}% treści.

Zasady:
- Tylko krótkie, konkretne zdania.
- NIE zdradzaj wydarzeń po {progress}%.
- Bez zbędnych słów i powtórzeń.

---

### Postacie
Wymień 4–6 kluczowych postaci.
- **Imię** — 1–2 zdania + _<u>relacja z głównym bohaterem</u>_

### Miejsca
Wymień 3–5 ważnych miejsc.
- **Miejsce** — 1 zdanie + _<u>kluczowe wydarzenie</u>_

### Główne tematy
- **Temat** — 1 zdanie

### Kluczowe pojęcia
- **Pojęcie** — bardzo zwięzłe znaczenie w tej książce

### Ostatnie punkty zwrotne
Wymień 5–8 ważnych wydarzeń (od najnowszego).
- **Scena/Rozdział:** jedno zdanie

### Powrót do lektury
- **Gdzie skończyłem:** 1–2 zdania
- **Otwarty konflikt:** 1 zdanie
- **Nastrój:** 1 zdanie
]],
    },

    -- -------------------------------------------------------------------------
    -- BOOK INFO — informacje o książce i autorze
    -- -------------------------------------------------------------------------
    book_info = {
        system_prompt = [[
Jesteś asystentem literackim. Podajesz rzetelne, zweryfikowane informacje o książkach.
Używaj Markdown. Odpowiadaj w {language}.]],
        user_prompt = [[
Podaj informacje o książce *{title}* ({author}).

### O książce
- Gatunek, rok wydania, liczba stron (jeśli znane).
- Krótki opis fabuły lub głównych tematów (maks. 5 zdań).

### O autorze
- Krótka nota biograficzna (3–4 zdania).
- Inne ważne dzieła.

### Kontekst historyczny i literacki
- W jakim czasie i kontekście powstała książka? (2–3 zdania)
- Jak jej tematy odnoszą się do epoki?

### Podobne książki
Polecane 3–5 książek o podobnym charakterze (temat, styl, gatunek):
- **Tytuł** (*Autor*) — jedno zdanie o podobieństwie

Odpowiedź w {language}.
]],
    },

    -- -------------------------------------------------------------------------
    -- DICT — słownik literacki (EN→PL lub PL, wykrywa język automatycznie)
    -- -------------------------------------------------------------------------
    dict = {
        system_prompt = [[
Jesteś słownikiem w stylu diki.pl dla polskiego czytelnika.
Odpowiadaj WYŁĄCZNIE po polsku.

Styl:
- bardzo zwięzły
- lista znaczeń (krótkie frazy, nie zdania)
- brak opisów i zbędnych wyjaśnień

Zasady:
- automatycznie rozpoznaj język słowa
- wykrywaj phrasal verbs i idiomy i traktuj je jako całość
- dla słów obcojęzycznych:
  - podawaj naturalne tłumaczenia na polski (krótkie)
  - synonimy w języku oryginału
  - przykład zawsze po polsku (tłumaczenie kontekstu)
- dla słów polskich:
  - krótkie definicje
  - synonimy po polsku
  - przykład po polsku
- znaczenia: maksymalnie 3
- synonimy: maksymalnie 3
- tylko jeden krótki przykład
- NIE używaj meta-komentarzy ani oznaczeń języka
- NIE tłumacz dosłownie idiomów
- zwracaj tylko gotowy wynik
]],

        user_prompt = [[
Wyjaśnij **"{word}"** z książki *{title}* ({author}).

# {word}

1. ...
2. ...
3. ...

_synonimy:_ ...

> ...

---
{context}
]],
},


    -- -------------------------------------------------------------------------
    -- DICT EN→PL — słownik angielsko-polski (używany przez assistant_dictdialog)
    -- -------------------------------------------------------------------------
    dict_en_pl = {
        system_prompt = [[
Jesteś słownikiem angielsko-polskim w stylu diki.pl.
Odpowiadaj WYŁĄCZNIE po polsku.

Styl:
- bardzo zwięzły
- lista znaczeń (krótkie frazy)
- brak opisów

Zasady:
- wykrywaj phrasal verbs i idiomy i traktuj je jako całość
- tłumaczenia: krótkie, naturalne (nie dosłowne dla idiomów)
- synonimy w języku angielskim (maks. 3)
- jeden krótki przykład po polsku (tłumaczenie kontekstu)
- maks. 3 znaczenia
- NIE używaj meta-komentarzy
- zwracaj tylko gotowy wynik
]],

        user_prompt = [[
Wyjaśnij **"{word}"** z książki *{title}* ({author}).

# {word}

1. ...
2. ...
3. ...

_synonimy:_ ...

> ...

---
{context}
]],
},


    -- -------------------------------------------------------------------------
    -- DICT PL — słownik języka polskiego (używany przez assistant_dictdialog)
    -- -------------------------------------------------------------------------
    dict_pl = {
        system_prompt = [[
Jesteś słownikiem języka polskiego w stylu PWN. Odpowiadaj WYŁĄCZNIE po polsku.
Używaj Markdown. Bądź zwięzły.]],
        user_prompt = [[
Wyjaśnij polskie słowo lub wyrażenie **"{word}"** z książki *{title}* ({author}).

początek template

### {word}

**Definicja:** [znaczenie słownikowe; maks. 3 punkty jeśli polisemiczne]
 1.
 2.
 3.

_Synonimy:_ [maks. 3 synonimy pasujące do kontekstu]

    
koniec template  stop


---
Kontekst:
{context}
]],
    },

    -- -------------------------------------------------------------------------
    -- SUGGESTIONS — propozycje pytań uzupełniających (dołączane do odpowiedzi)
    -- -------------------------------------------------------------------------
    suggestions_prompt = T([[
Na końcu odpowiedzi zaproponuj 2–3 krótkie pytania uzupełniające w języku {language}.
Pytania muszą wynikać z treści odpowiedzi.
Krytyczne: pytania NIE mogą zawierać znaków interpunkcyjnych — tylko litery i spacje.
Sformatuj jako listę Markdown z hiperłączami:

```
---
__%1__

- [Pytanie 1](#q:Pytanie 1)
- [Pytanie 2](#q:Pytanie 2)
```
]], _("You may also ask:")),
}


-- =============================================================================
-- HELPERS
-- =============================================================================

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
        if a[key] == nil or b[key] == nil then return false end
        return a[key] < b[key]
    end)
end


-- =============================================================================
-- MODULE
-- =============================================================================

local M = {
    custom_prompts            = custom_prompts,
    assistant_prompts         = assistant_prompts,
    merged_prompts            = nil,
    sorted_custom_prompts     = nil,
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
    if M.sorted_custom_prompts then return M.sorted_custom_prompts end
    local sorted_prompts = {}
    for prompt_index, prompt in pairs(M.merged_prompts or custom_prompts) do
        if not filter_func or filter_func(prompt, prompt_index) == true then
            table.insert(sorted_prompts, {
                idx   = prompt_index,
                order = prompt.order or 1000,
                text  = prompt.text or prompt_index,
                desc  = prompt.desc or "",
            })
        end
    end
    table_sort(sorted_prompts, "order")
    return sorted_prompts
end

return M
