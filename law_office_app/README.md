# Law Office Document Generator

A small, **fully local** web app for a law office. Pick a matter type, fill in
a form, and download a finished `.docx` document generated from a Word template.
No data ever leaves your machine: documents are written to `generated/` and a
record of each is kept in a local SQLite database.

Built with **Python**, **Flask**, **SQLite**, and **python-docx**.

Ships with three starter templates:

- **Divorce Petition** – petition for dissolution of marriage
- **Parenting Plan** – custody and parenting time agreement
- **Notice of Hearing** – notice setting a matter for hearing

---

## Quick start

```bash
# 1. (recommended) create a virtual environment
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate

# 2. install dependencies
pip install -r requirements.txt

# 3. generate the starter Word templates
python create_templates.py

# 4. run the app
python app.py
```

Then open <http://127.0.0.1:5000> in your browser.

Pick a matter, fill in the form, and click **Generate .docx**. The file
downloads automatically and also appears under **History**, where you can
re-download any previously generated document.

---

## Folder structure

```
law_office_app/
├── app.py                 # Flask app + routes
├── config.py              # paths and settings (all local)
├── matters.py             # matter type + form field definitions  <-- edit to add matters
├── document_generator.py  # fills {{ placeholders }} in .docx templates
├── database.py            # local SQLite storage of generated docs
├── create_templates.py    # generates the starter .docx templates
├── requirements.txt
├── README.md
├── doc_templates/         # the Word templates with {{ placeholders }}
│   ├── divorce_petition.docx
│   ├── parenting_plan.docx
│   └── notice_of_hearing.docx
├── templates/             # HTML (Jinja) for the web UI
├── static/                # CSS
├── generated/             # output .docx files (git-ignored)
└── data/                  # SQLite database (git-ignored)
```

> **Privacy:** `data/` and generated `.docx` files are excluded from git via
> `.gitignore` so client information is never committed.

---

## How it works

1. `matters.py` defines each matter type: its label, the template file it uses,
   and the list of form fields.
2. The web form is built automatically from those field definitions.
3. On submit, `document_generator.py` opens the matching `.docx` template and
   replaces every `{{ field_name }}` placeholder with the value entered in the
   form. Placeholders that span multiple Word "runs" are handled, and any
   placeholder left blank simply renders as empty text.
4. The finished document is saved to `generated/` and logged in SQLite.

---

## Adding a new template / matter type

Adding a matter takes two steps — one in code, one in Word.

### Step 1 — Describe the matter in `matters.py`

Add an entry to the `MATTER_TYPES` dictionary:

```python
"custody_motion": {
    "label": "Motion to Modify Custody",
    "description": "Motion to modify an existing custody order.",
    "template": "custody_motion.docx",   # filename in doc_templates/
    "client_field": "movant_name",        # field used to label the matter in History
    "fields": _COURT_FIELDS + [
        {"name": "movant_name", "label": "Movant Full Name",
         "type": "text", "required": True, "section": "Parties"},
        {"name": "current_order_date", "label": "Date of Current Order",
         "type": "date", "required": False, "section": "Background"},
        {"name": "requested_change", "label": "Requested Modification",
         "type": "textarea", "required": True, "section": "Relief"},
    ] + _ATTORNEY_FIELDS,
},
```

Each field is a dictionary with:

| key        | meaning                                                        |
|------------|----------------------------------------------------------------|
| `name`     | the placeholder name — becomes `{{ name }}` in the template     |
| `label`    | the label shown in the form                                    |
| `type`     | `text`, `textarea`, `date`, or `time`                          |
| `required` | `True`/`False` — required fields are validated before generating |
| `section`  | groups fields under a heading in the form                      |
| `help`     | (optional) hint text shown beneath the field                   |

You can reuse the shared `_COURT_FIELDS` and `_ATTORNEY_FIELDS` groups, as the
built-in matters do.

### Step 2 — Create the Word template

Create `doc_templates/custom_motion.docx` (matching the `template` filename)
and write your document in Word. Wherever you want a value inserted, type the
placeholder using **double curly braces**:

```
COMES NOW the Movant, {{ movant_name }}, and moves this Court to modify the
custody order entered on {{ current_order_date }} as follows:

{{ requested_change }}
```

Tips:

- Placeholder names must match the field `name` values exactly.
- Keep each placeholder as plain text (avoid splitting `{{` and `}}` with
  formatting changes mid-token — though the generator does try to handle that).
- Placeholders work in body text, **tables**, headers, and footers.
- The shared court caption and attorney signature block use placeholders like
  `{{ court_county }}` and `{{ attorney_name }}` — include those names in your
  field list (the `_COURT_FIELDS` / `_ATTORNEY_FIELDS` groups already do).

That's it. Restart the app and the new matter appears on the home page.

> Prefer to author starter templates in code? Add a `build_...` function and an
> entry to `BUILDERS` in `create_templates.py`, then re-run it.

---

## Configuration

Settings live in `config.py` and can be overridden with environment variables:

| Variable             | Default       | Purpose                          |
|----------------------|---------------|----------------------------------|
| `LAW_OFFICE_HOST`    | `127.0.0.1`   | bind address (localhost only)    |
| `LAW_OFFICE_PORT`    | `5000`        | port                             |
| `LAW_OFFICE_SECRET`  | `dev-only...` | Flask secret key for flash msgs  |

The app binds to `127.0.0.1` by default so it is reachable only from your own
computer.

---

## Notes & disclaimer

These templates are **starting points**, not legal advice or court-approved
forms. Review every generated document and adapt the templates to your
jurisdiction's rules and local court requirements before filing.
