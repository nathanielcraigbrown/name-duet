# Active Name Pool Etymology Quality Report

## Scope

This package covers the complete active pool created by migration 010:

- 100 names from the 2025 SSA girls' ranking
- 60 curated names
- 15 overlaps
- **145 unique names total**

The display fields are deliberately concise. The CSV retains canonical source names, relationship types, confidence, source families, and research notes.

## Confidence summary

- High confidence: **101**
- Medium confidence: **42**
- Low confidence: **2**
- Total: **145**

A medium rating usually means that the name has more than one established origin, that the ancient root is disputed, or that a modern spelling can descend from more than one source name. It does not mean that the entry is unsupported.

## Low-confidence entries requiring human review

- **Ailany** — Modern American / Hawaiian-influenced · modern form; exact derivation uncertain. Rare modern spelling, commonly treated as a variant of Ailani or Kailani; exact formation is not firmly documented.
- **Euroletta** — Rare literary / American usage · rare historic name; etymology unverified. Documented as a rare historical personal name, but no reliable linguistic derivation has been established.

## Important ambiguity categories

### Multiple legitimate origins

The following names have multiple established linguistic traditions or source lines. Their display meanings summarize the principal possibilities rather than pretending that one origin is universal:

**Eliana**, **Ava**, **Nora**, **Aria**, **Riley**, **Maya**, **Ayla**, **Amara**, **Celia**, **Nina**, **Ada**, and **Esme**.

### Variants, diminutives, and feminine forms

Many current names inherit their etymology from an older canonical form. The CSV records the canonical source and relationship explicitly. Examples include Zoey → Zoe, Madelyn → Madeline, Sadie → Sarah, Josie → Josephine, Gianna → Giovanna, and Charlotte → Charles.

### Surname and place-name transfers

Names such as Harper, Avery, Madison, Riley, Paisley, Addison, Kennedy, Everly, Kinsley, Quinn, Greer, Skye, Caledonia, and Sienna entered given-name use through surnames, place names, or both. Their meanings are presented as historical derivations, not as promises about a child's character.

### Vocabulary, botanical, seasonal, and gemstone names

Violet, Lily, Hazel, Willow, Nova, Grace, Ivy, Daisy, Melody, Autumn, Jade, Juniper, Rose, June, Summer, Flora, and Ruby have transparent vocabulary or natural-world sources. Their etymologies are generally high confidence.

## Research cautions

- Ancient names such as Eleanor, Penelope, Leah, Maria, Elena, Helena, and Juliet have traditional interpretations, but their deepest roots are disputed.
- Modern spellings such as Ailany and Lyla require careful variant handling. The display fields use cautious wording and the CSV preserves the uncertainty.
- Euroletta is documented as a rare historical personal name, but a reliable linguistic derivation was not found. The entry intentionally says so rather than inventing a meaning.
- Commercial baby-name claims that add flattering but unsupported meanings were excluded.

## Source methodology

Primary reference families used throughout the catalog:

1. Behind the Name, including its cited academic and dictionary references
2. *The Oxford Dictionary of First Names* and *The Oxford Dictionary of Family Names*
3. Wiktionary for transparent source-language words and historical forms
4. Specialized language and place-name references where appropriate, including Hawaiian, Irish, Nordic, and British place-name sources
5. Historical and SSA usage records for rare modern forms

The `source_1` and `source_2` columns identify the strongest source families used for each row. The two low-confidence entries should be revisited if a scholarly onomastic source becomes available.

## Validation

The generated package was programmatically checked for:

- exactly 145 rows
- exactly 100 SSA-ranked rows
- exactly 45 curated-only rows
- no duplicate display names
- no blank origin
- no blank meaning
- all names represented in the SQL migration
- confidence values restricted to high, medium, or low
