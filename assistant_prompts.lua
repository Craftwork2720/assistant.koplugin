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
## Your Role

You are a literary analyst creating context-aware entries that explain how narrative elements are presented and used in this specific book.

**Your primary task:** Analyze the highlighted term "{highlight}" specifically as it appears in "{title}" by {author}—not as a generic concept, but as a story element.

**Context Quality Note:** You have been provided with {context_sentence_count} relevant sentences from the book selected by AI analysis of similarity to this term.

## How to Use the Context Provided

**The following text is from the book, selected for relevance to "{highlight}":**

The context includes not only sentences explicitly mentioning "{highlight}" but also surrounding sentences. This captures important related context such as:

**For character terms:** Pronouns (he, she, they) and actions showing what they do
**For objects/things:** Descriptions, properties, how they're used, effects ("it", "that" references)
**For places/locations:** Geography, significance, events that occur there
**For concepts/magic:** How they work, limitations, consequences, symbolic meaning
**For abstract elements:** Definition through usage, effects, relationships to other story elements

**Important:** The context sentences are presented in chronological order as they appear in the book. Use this ordering to understand how the term develops and its context throughout the narrative. Nearby actions, events, character interactions, dialogue, and environmental details are included to show the term in context.

**You must:**
1. Ground your analysis in the provided context—do not use general knowledge beyond what's shown
2. Identify specific examples from the context that illustrate the term's meaning and function
3. Pay special attention to **all pronouns and implied references** to "{highlight}":
   - Character pronouns: he, she, they → for people and creatures
   - Thing pronouns: it, that, this → for objects, places, concepts, magic, elements
4. For objects/things: Note descriptions, properties, physical characteristics, and how the thing is used
5. For places: Note location, geography, significance, and events that occur there
6. For concepts/magic: Note how they work, their rules/limitations, consequences, and symbolic meaning
7. Consider the chronological progression of the context sentences as they appear in the book to understand how the term develops and changes
8. Note if the context is limited and what important information may be missing
9. Distinguish between how the term is used in this book versus typical usage

## Analysis Structure

### What It Is
[How the term is defined/described in the book, based on the provided context. Include specific examples.]
- **If a character:** Note pronouns and descriptions that clarify their identity, appearance, and basic traits
- **If an object/thing:** Describe its physical properties, materials, appearance, and purpose
- **If a place/location:** Describe its geography, scale, distinctive features, and atmosphere
- **If a concept/magic:** Explain how it works, what makes it unique in this world, its fundamental nature
- **If an element/force:** Describe its composition, behavior, effects, and properties

### Role & Function in This Story
[How the term functions in the narrative. What does it reveal about the story? Ground in the context provided.]
- **If a character:** What do they do? What motivations and relationships are shown? What is their significance?
- **If an object/thing:** How is it used? What does it enable or prevent? What consequences does it have?
- **If a place/location:** What happens there? Why is it significant? What role does it play in the story?
- **If a concept/magic:** How does it affect the plot? What are its limitations? What can and cannot be done with it?
- **If an element/force:** What does it do? What are its effects on other story elements? Who uses it and how?

### Evolution & Development (if applicable)
[How the term's meaning, perception, or role changes as the story progresses. Consider the chronological flow of the provided context.]
- Track how understanding of the term deepens or changes as you progress through the context
- Note early vs. late references and what new information appears
- Show how the term's importance or usage shifts over time

### Connections to Other Elements (if apparent from context)
[How the term relates to other characters, places, themes, or story elements mentioned in the provided context.]
- Note all pronouns and implied relationships ("it was used by...", "it affected...", "they created it...")
- For objects: Who uses it? What do they use it for?
- For places: Who lives there? What events happen there? Who goes there?
- For concepts: Who understands it? Who is affected by it?
- For magic/elements: What interactions does it have with other elements? Who can use it?

### Context Limitations
[If the provided context seems insufficient to fully explain this term, note what important information appears to be missing.]
- What aspects are underexplained?
- What questions does the context leave unanswered?
- What related information would help explain this term better?

## Formatting Requirements

Most importantly, **Respond in this language:** {language}

**Writing Style:**
- Write in clear, accessible language—avoid jargon
- Use present tense when describing the fictional world
- Ground every claim in the provided context (cite implicitly: "As shown in the context..." is unnecessary unless context is unclear)
- If making inferences beyond the context, explicitly state: "Based on the context provided..." or "Inferred from..."
- Do NOT use general knowledge about this book if not shown in the context
- **Respond in this language:** {language}

**Structure:**
- Use headers (###) to organize sections
- Write in flowing prose; use bullet points only for genuine lists
- Keep total length to 300-400 words
- Prioritize understanding over encyclopedic completeness

## User Input
{user_input}

## Context from the Book
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
        user_prompt = [[Translate this to {language}: Output only the translated text without any further explanation.

Follow these steps to complete the translation:
1. Read the source text carefully to understand its content, context, and tone.
2. Translate the text into the target language, focusing on conveying the meaning accurately rather than translating word-for-word.
3. Ensure that the translation sounds natural and fluent in the target language, adjusting sentence structures and word choices as necessary.
4. Pay attention to idiomatic expressions, cultural references, and figurative language in the source text. Adapt these elements appropriately for the target language and culture.
5. Maintain the original text's tone and style (e.g., formal, casual, technical) in the translation.
6. If you encounter any terms or concepts that are difficult to translate directly, provide the best equivalent in the target language and include a brief explanation in parentheses if necessary.
7. Double-check your translation for accuracy, consistency, and proper grammar in the target language.
8. If there are any parts of the text that you are unsure about or that require additional context to translate accurately, indicate these areas with [UNCERTAIN: explanation] in your translation.

[TEXT TO BE TRANSLATED]
{highlight}
[END OF TEXT]
]],
    },
    summarize = {
        text = _("Summarize"),
        order = 40,
        desc = _("This prompt summarizes the highlighted text, capturing its main points and essential details."),
        user_prompt = [[
You are an exceptionally skilled summarization expert and a master of linguistic precision.
Your core competency is to distill extensive information into its most essential form while rigorously adhering to the original language of the input text.
Your task is to receive the following text and provide a summary that is both genuinely concise and remarkably clear.
This summary must accurately capture every main point and crucial detail, eliminating all extraneous information, so that a reader can grasp the complete essence of the original content quickly and effectively, exclusively in its native language.
Please provide a concise and clear summary of the following text in its own language: {highlight}]],
    },
    simplify = {
        text = _("Simplify"),
        order = 50,
        desc = _("This prompt simplifies the highlighted text to make it easier to understand."),
        user_prompt =
        [[You are an experienced linguistic expert and an effective communicator, skilled at transforming complex content into clear, easily understandable expressions.
I have a piece of text that I need you to simplify using its original language.
Please ensure that during the simplification process, you do not alter the text's original meaning or omit any critical information.
Instead, make it significantly easier to understand and read, removing unnecessary jargon and verbose phrasing.
Your goal is to enhance the text's readability and clarity, making it accessible to a broader audience.

{highlight}]],
    },
    explain = {
        text = _("Explain"),
        order = 80,
        desc = _("This prompt explains the highlighted text in detail, ensuring clarity and understanding."),
        user_prompt = [[You are an expert Explainer and a highly skilled Cross-Cultural Communicator.
Your task is to accurately and comprehensively explain any given text.
When I provide you with text, regardless of its original language, your primary goal is to fully grasp its meaning, including all complex terms, underlying concepts, and implicit details.
You must then provide a clear, detailed, and easy-to-understand explanation of the entire text.
It is crucial that your *entire explanation* is delivered exclusively in **{language}**.
Ensure your {language} explanation is precise, captures all nuances of the original text, and is formatted for maximum clarity, potentially using prose or structured points as needed.

{highlight}]],
    },
}


local assistant_prompts = {
    default = {
        system_prompt = [[
Jesteś pomocnym asystentem czytelnika. Odpowiadaj zwięźle i rzeczowo.
Zawsze używaj Markdown. Odpowiadaj w języku {language}.]],
    },
    recap = {
        system_prompt =
        "You are an expert literary assistant that provides accurate information about books. Always respond in Markdown format.",
        user_prompt = [[
'''{title}''' by '''{author}''' that has been {progress}% read.
Given the above title and author of a book and the positional parameter, very briefly summarize the contents of the book prior with rich text formatting.
Above all else do not give any spoilers to the book, only consider prior content.
Focus on the more recent content rather than a general summary to help the user pick up where they left off.
Match the tone and energy of the book, for example if the book is funny match that style of humor and tone, if it's an exciting fantasy novel show it, if it's a historical or sad book reflect that.
Use text bolding to emphasize names and locations. Use italics to emphasize major plot points. No emojis or symbols.
Answer this whole response in {language} language. Only show the replies, do not give a description.
Also answer with entertaining tone and high quality detail with a focus on summarization. You also match the tone of the book provided.]]
    },
    xray = {
        system_prompt =
        "You are an expert literary assistant that provides accurate information about books. Always respond in Markdown format.",
        user_prompt = [[
Your output must be spoiler‑free beyond the reader’s current progress.

Required structure (Markdown):

### Characters
- **Name** — brief description(3 sentences) _<u>relationship(s) with others</u>_

### Locations
- **Place** — brief description(3 sentences) _<u>notable event(s) there</u>_

### Main Themes
- **Theme** — brief description(3 sentences) of how it appears up to now

### Terms & Concepts
- **Term** — concise definition / significance

### Timeline
List around 8 to 12 **key chapters or scenes** that were most important to the plot up to the current point.  Use this format:
- **Chapter X:** one-sentence summary of the significant event.
Do NOT list every chapter in order; only include meaningful turning points, character developments, or major events relevant to the ongoing story.

### Re-immersion
* **Where the action stopped:** *2 sentences*
* **Protagonist’s current objective:** *1 sentence*
* **Open conflict or mystery:** *1 sentence*
* **Narrative element in focus:** *1 sentence* (object, place, or symbol)
* **Prevailing emotional state/tone:** *1 sentence*
* **Outstanding questions:** *1 sentence*

Formatting rules:
* Use bullet (–) or ordered list as shown.
* Show at least 8–15 characters, 6–10 locations, 5–8 themes, 5–10 terms/concepts, and every major chapter reached so far in Timeline.
* Put relationship or event strings in italic & underlined using Markdown `_` and `<u>` tags combined (e.g. _<u>ally of Frodo</u>_).
* Do NOT reveal content past the given progress percentage.
* Answer entirely in **{language}** and return only the X‑Ray, nothing else.

Generate the expanded X‑Ray for **{title}** by **{author}**, with the structure described above.
Reader progress: **{progress}%**.
Language: **{language}**.
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
        "You are a concise dictionary assistant. Always respond in Markdown format.",
        user_prompt = T([[
Explain the word "{word}" as used in "{title}" by {author}.

Context from the book:
{context}

Provide only these sections:

*%1*: The meaning of "{word}" in plain terms. Answer in {language} language.
*%2*: Translation of the sentence containing the word. Highlight the translated word in **bold**. Answer in {language} language.
*%3*: Up to two synonyms most relevant to this context.

Keep answers short and direct. No etymology, no additional commentary.
]],
            _("Meaning"),
            _("Translation"),
            _("Synonyms"))
    },
    
    -- -------------------------------------------------------------------------
    -- DICT EN→PL — słownik angielsko-polski (używany przez assistant_dictdialog)
    -- -------------------------------------------------------------------------
    dict_en_pl = {
        system_prompt =
        "You are a concise English-Polish dictionary assistant. Always respond in Markdown format.",
        user_prompt = T([[
Explain the English word "{word}" as used in "{title}" by {author}.

Context from the book:
{context}

Provide only these sections:

*%1*: The meaning of "{word}" in plain terms. Answer in Polish.
*%2*: Polish translation of the word "{word}" (single word or short phrase).
*%3*: Translation of the sentence containing the word into Polish. Highlight the translated word in **bold**.

Keep answers short and direct. No etymology, no additional commentary.
]],
            _("Meaning"),
            _("Polish translation"),
            _("Sentence translation"))
    },



    -- -------------------------------------------------------------------------
    -- DICT PL — słownik języka polskiego (używany przez assistant_dictdialog)
    -- -------------------------------------------------------------------------
    dict_pl = {
        system_prompt =
        "You are a concise Polish dictionary assistant for difficult and foreign words. Always respond in Markdown format.",
        user_prompt = T([[
Wyjaśnij polskie słowo "{word}" użyte w "{title}" autorstwa {author}.

Kontekst z książki:
{context}

Podaj tylko te sekcje:

*%1*: Znaczenie słowa "{word}" prostymi słowami, po polsku. Jeśli to wyraz obcy lub archaiczny, zaznacz to.
*%2*: Synonimy lub prostsze zamienniki (max 2–3 słowa).

Odpowiedzi krótkie i rzeczowe. Bez etymologii, bez zbędnych komentarzy.
]],
            _("Znaczenie"),
            _("Synonimy"))
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
