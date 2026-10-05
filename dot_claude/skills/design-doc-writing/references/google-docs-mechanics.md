# Google Docs mechanics for HLD work

Read this before the first Drive or Docs call. If a `google-workspace` skill is available, read it and its `references/docs.md` first; this file adds the lessons from building an HLD end to end.

## Tools and what each is for

- **Drive `copy_file`:** copy the user's template. Give the copy a descriptive title. Never edit the original.
- **Drive `read_file_content`:** returns the doc as Markdown. Use it to read content and to verify after edits. It is not index space, and it escapes formatting (bold paragraphs can show as `\*\*text\*\*` even though the doc contains no asterisks). If in doubt, check the `read_doc` JSON for literal `*`.
- **Docs `read_doc`:** full JSON with indexes and `revisionId`. The result is large and is saved to a file. The saved file is a list whose first item has a `text` field holding a JSON string, so unwrap it: `json.loads(w[0]['text'])['content']`. Write that to a file before using helper scripts.
- **Docs `update_doc`:** takes `requests` and `writeControl: {requiredRevisionId}`. Pass the revision from your latest read so a concurrent user edit fails loudly instead of corrupting indexes.

The user edits the doc between turns, so always re-read before editing by index.

## Prefer `replaceAllText` for wording changes

It needs no indexes. Use text unique to the target (add neighboring words until it is), set `tabsCriteria` to the tab, and confirm `occurrencesChanged` is 1 for each request. A `\n` in `replaceText` creates a new paragraph that inherits the original's list formatting, which is the easiest way to add a bullet or numbered item. Text replaced inside a link inherits the link, so avoid replacing linked text unless you restyle afterward.

## Index-based edits

- In one batch, apply edits from the highest index to the lowest so earlier requests do not shift later ones.
- To fill a template: empty paragraphs after headings are often styled as headings. Insert the body text there, then set the range to `NORMAL_TEXT`. If a heading has no empty paragraph after it, insert the new paragraphs at the start of the next heading with a trailing newline, then restyle.
- Inserted text inherits the style around it, including links and bold. After inserting near a link, clear it: `updateTextStyle` with an empty `textStyle` and `fields: "link"` (or `"link,bold"`).
- Compute link and bold ranges from the inserted text and `str.index`, then read back and check each link sits on the intended phrase. A range that is off by one line is easy to miss.

## Rewriting a large region

Replacing everything after a given heading is cheaper than many patches:

1. `deleteContentRange` from the heading's start to the document end minus one (the last newline cannot be deleted; this leaves one empty paragraph).
2. `insertText` the full new text at that start index.
3. `deleteParagraphBullets` over the region, then set it to `NORMAL_TEXT`, then clear `link,bold`.
4. Set headings (`HEADING_2`, `HEADING_3`) per paragraph, then bold and links.
5. Create bullets last.

If the region contains a table, rebuild it afterwards with the helper (`docs_index.py new-table`) at the end of the paragraph that precedes it.

## Nested bullets

Put one leading `\t` per nesting level in the inserted text, then call `createParagraphBullets` (`BULLET_DISC_CIRCLE_SQUARE` renders disc then circle). Creating the bullets removes the tabs, which shifts every later index. So apply all bold and link styling first, create the bullet groups last, and process groups from the highest index to the lowest.

Numbered lists use `NUMBERED_DECIMAL_ALPHA_ROMAN`.

## Tables

- **New table:** `docs_index.py new-table --at <endIndex-1 of the preceding paragraph> --data rows.json --tab <tabId> --revision <rev> --bold-header`. Append its requests to your batch after all earlier styling (the table shifts everything after it).
- **New column:** `insertTableColumn` with `insertRight: true`, then read again and insert text at each new cell's first-paragraph start index (cell start + 1). Bold the header cell.
- **New row:** `insertTableRow` with `insertBelow: true`, read again, insert text per cell, and set `bold: false` if the row inherited header styling.
- Keep cell text to a few words. Wide tables of six columns are fine at that length.

## Deleting a final section

Delete from the previous paragraph's `endIndex - 1` to the last paragraph's `endIndex - 1`. Deleting `[start, end]` of the last paragraph is refused.

## Checks after editing

- Read back with Drive `read_file_content`: headings, list nesting, links on the right phrases, table cells, counts mentioned in prose (for example "the seven requirements").
- Check `documentStyle.documentFormat.documentMode` in the `read_doc` JSON. If it is `PAGELESS`, page count cannot be measured; estimate from word count and say you could not confirm it. Never claim you checked the rendering unless you did.
- A person smart chip (for example in an Author field) cannot be edited as text; leave it as is.
