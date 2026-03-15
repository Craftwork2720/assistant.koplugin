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
        order = -20, -- negative number to not show on additional questions dialog
        desc = _(
            "This prompt creates a structured system for generating context-aware definitions of words or phrases from literature by analyzing the highlighted term within its surrounding text to provide nuanced explanations that capture both literal meaning and contextual significance."),
        system_prompt =
        "You are a literary analyst who creates clear, encyclopedic descriptions of narrative elements. Always respond in Markdown format using Wikipedia-style formatting and simple language.",
        user_prompt = [[
Explain the term "{highlight}" as used in "{title}" by {author}, based ONLY on the provided context.

Rules:
- Max 180–220 words.
- Be concise and factual.
- No generic knowledge outside context.
- No introductions or conclusions.
- Use short paragraphs.

Structure:

### What It Is
Brief definition based on context.

### Role in Story
How it functions in the narrative so far.

### Key Detail
1–2 important contextual observations.

Respond only in {language}.

Context:
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
    vocabulary = {
        text = _("Vocabulary"),
        order = 10,
        desc = _("This prompt analyzes the vocabulary of the highlighted text, identifying complex words and providing definitions, synonyms, and usage examples."),
        user_prompt = [[
Find B2+ words in the text.

For each word:
- Base form
- Up to 2 simple synonyms
- Short explanation in {language}

Format strictly:
1. __word__: synonym1, synonym2 : short explanation

Only list. No extra text.

Text:
{highlight}
]],
    },
    grammar = {
        text = _("Grammar"),
        order = 20,
        desc = _(
            "This prompt analyzes the grammar of the highlighted text, providing a detailed explanation of its structure and any grammatical errors."),
        system_prompt =
        "You are a helpful AI assistant. Always respond in Markdown format, but use markdown lists to present comparisons instead of tables.",
        user_prompt =
        [[
Briefly explain the grammar of the text.

Focus on:
- sentence structure
- verb tense
- unusual constructions
- errors (if any)

Max 6–8 short bullet points.
No long theory.
Only {language}.

Text:
{highlight}]],
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
Summarize the text briefly.

- Max 5 short sentences.
- Focus only on main idea.
- No repetition.
- No filler.
- Use the original language.

Text:
{highlight}]],
    },
    simplify = {
        text = _("Simplify"),
        order = 50,
        desc = _("This prompt simplifies the highlighted text to make it easier to understand."),
        user_prompt =
        [[
Rewrite the text in simpler language.

- Keep original meaning.
- Shorter sentences.
- Remove complex wording.
- No added explanations.

Text:
{highlight}]],
    },
    key_points = {
        text = _("Key Points"),
        order = 60,
        desc = _(
            "This prompt extracts and lists the key points from the highlighted text, ensuring clarity and organization."),
        user_prompt =
        [[
Extract key points.

- 5–8 bullet points.
- Each point max 1 sentence.
- Only essential ideas.
- No commentary.

Respond in {language}.

Text:
{highlight}]],
    },
    ELI5 = {
        text = _("ELI5"),
        order = 70,
        desc = _(
            "This prompt explains the highlighted text as if to a five-year-old, simplifying complex concepts into easily understandable terms."),
        user_prompt =
        [[
Explain this like to a child.

- 3–5 very short sentences.
- Very simple words.
- No metaphors unless helpful.

Only {language}.

Text:
{highlight}
]],
    },
    explain = {
        text = _("Explain"),
        order = 80,
        desc = _("This prompt explains the highlighted text in detail, ensuring clarity and understanding."),
        user_prompt = [[
Explain the highlighted text clearly.

Rules:
- 4–6 short sentences.
- Focus on core meaning.
- Clarify difficult words briefly.
- No repetition.
- No introduction or conclusion.

Respond only in {language}.

Text:
{highlight}
]],
    },
    historical_context = {
        text = _("Historical Context"),
        order = 90,
        desc = _(
            "This prompt provides a detailed historical context for the highlighted text, explaining its significance and background."),
        user_prompt =
        [[
Briefly explain the historical context relevant to this text.

- Max 6 short sentences.
- Only directly relevant background.
- No broad essays.

Respond in {language}.

Text:
{highlight}
]],
    },
    wikipedia = {
        text = _("Wikipedia"),
        order = 100,
        desc = _(
            "This prompt generates a comprehensive Wikipedia-style article based on the highlighted text, ensuring factual accuracy and neutrality."),
        user_prompt =
        [[
Write a concise encyclopedic entry.

Structure:
- Short intro paragraph
- 3–5 short sections

Be neutral and factual.
Max 300 words.
Only {language}.

Topic:
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
]]
    },
    xray = {
        system_prompt =
        "You are an expert literary assistant that provides accurate information about books. Always respond in Markdown format.",
        user_prompt = [[
Your output must be spoiler-free beyond the reader’s current progress.

Keep it concise and readable for an e-reader.

Required structure (Markdown):

### Characters
List 4–6 key characters.
- **Name** — 1–2 short sentences _<u>relationship</u>_

### Locations
List 3–5 important places.
- **Place** — 1 short sentence _<u>notable event</u>_

### Main Themes
List 3–5 themes.
- **Theme** — 1 short sentence

### Key Terms
List 3–5 important terms or concepts.
- **Term** — very concise meaning

### Recent Turning Points
List 5–8 major events only.
- **Chapter / Scene:** one short sentence

### Re-immersion
* **Where we stopped:** 1–2 short sentences
* **Current objective:** 1 sentence
* **Open conflict:** 1 sentence
* **Tone:** 1 sentence

Rules:
- Short sentences only.
- No filler.
- No repetition.
- Do NOT reveal events beyond {progress}%.
- Answer only in {language}.
- Return only the structured X-Ray.

Book: {title} by {author}  
Progress: {progress}%
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
    annotations = {
        system_prompt =
        "You are an expert literary assistant that provides accurate information about books. Always respond in Markdown format.",
        user_prompt = [[
You are given  my notes and highlights.
Your task is to carefully analyze this content and produce a structured summary that includes:

1. **Key Takeaways**
   - Summarize the most important insights, lessons, or narrative developments.
   - Highlight recurring themes, turning points, or critical information.

2. **To-Do / Action Items**
   - Based on the content and my notes, suggest practical actions, reflections, or follow-ups I should consider.
   - If the text is fictional, focus on intellectual or emotional takeaways (e.g., themes to reflect on, characters to analyze, related readings).
   - If the text is non-fiction, focus on actionable steps (e.g., habits to adopt, ideas to research, concepts to apply).

3. **Contextual Notes**
   - Clarify connections between my highlights/notes and the broader narrative or arguments.
   - Point out any open questions or areas I may want to revisit in the earlier chapters.

Output format:
- Start with a concise **executive summary** (3–5 sentences).
- Then provide a **detailed list** under “Key Takeaways” and “To-Do / Action Items.”
- End with **Contextual Notes / Reflections** in bullet points.

Keep the tone clear, thoughtful, and practical.
- Always respond in {language}.]],
    },
    summary_using_annotations = {
        system_prompt =
        "You are an expert literary assistant that provides accurate information about books. Always respond in Markdown format.",
        user_prompt = [[
You are a meticulous book summarizer and analyst.

INPUTS:
- book_text: the full text of the book (or a very large portion, potentially thousands of words)
- highlights: a list of highlighted passages and my personal notes

YOUR TASK:
Produce a **structured summary** that integrates the highlights naturally into the book summary.
Do not separate highlights into a final section — instead, use a translated summary of each highlight inside the summary to emphasize them at the right place.

STYLE & RULES:
1. Language → Always respond in {language}.
2. TL;DR → Begin with a 2–3 sentence overall summary of the book’s main message.
3. Integrated Summary:
   - Provide a clear, logical summary of the book.
   - Each time you encounter a highlight, render the exact highlighted text in **bold**.
   - Immediately after the bold text, paraphrase it and explain why it matters in the context of the book.
   - If a highlight has a note, include it in *italic parentheses* right after your explanation.
   - Maintain flow: highlights must feel naturally embedded, not forced.
4. Key Points:
   - After the integrated summary, list the 8–12 most important insights in bullet form.
   - Incorporate highlights into the list (again in **bold**), paraphrased where helpful.
5. Actionable Takeaways:
   - Provide 5–8 clear, practical lessons or insights the reader can apply.
6. Tone:
   - Clear, thoughtful, and practical.
   - Never copy the entire book verbatim; focus on essence and integration of highlights.
7. Contradictions:
   - If a highlight conflicts with the book text, mark it with ⚠️ and briefly note the possible interpretation.
   - If a highlight is not related to the book text (if it is not in the book text), ignore it.

OUTPUT STRUCTURE (Markdown):
- TL;DR
- Integrated Summary
- Key Points
- Actionable Takeaways
- ⚠️ Contradictions / Open Questions (if any)

IMPORTANT:
- Always weave highlights *inline*, never at the end.
- Keep formatting consistent (Markdown headings, bold highlights, italic notes).
- If the text is extremely long, compress intelligently while still reflecting highlights.

Now begin the analysis with the provided book_text and highlights.]],
    },

    dict = {
        system_prompt =
        "You are a literary dictionary that explains words in their book context. Always respond in Markdown format.",
        user_prompt = [[
## Task: Book-Aware Word Analysis

Explain the highlighted term "{word}" as used in "{title}" by {author}, based on the provided context. Be concise. Do not exceed the requested length.


## Context from the Book
The following sentences contain or relate to "{word}":
{context}

## Format

Start the response with:
### {word}

Then provide the requested sections below.

## Analysis

### FORMATTING RULES:
1. If the word "{word}" is in ENGLISH:

- **Tłumaczenie**: (Short translation into {language})

- **Synonimy**: Up to three concise synonyms that best match the word’s meaning in THIS context. 
  Prioritize synonyms that reflect how the word is actually used in the book.

- **Kontekst**: Literal meaning of the word as used in this context.
  Explain concisely in {language} language.
  Focus on contextual meaning, not only a generic dictionary definition.
  If the usage appears symbolic, archaic, poetic, or genre-specific, reflect that briefly.

2. If the word "{word}" is in POLISH:

- **Synonimy**: Up to three concise synonyms that best match the word’s meaning in THIS context. 
  Prioritize synonyms that reflect how the word is actually used in the book.

- **Kontekst**: Literal meaning of the word as used in this context.
  Explain concisely in {language} language.
  Focus on contextual meaning, not only a generic dictionary definition.
  If the usage appears symbolic, archaic, poetic, or genre-specific, reflect that briefly.

Show only the heading and the requested sections. No introduction or additional commentary.
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
