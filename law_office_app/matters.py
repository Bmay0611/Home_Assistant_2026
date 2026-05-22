"""Matter type definitions.

Each matter type describes the form fields shown in the web UI and the
.docx template used to generate the document. Field ``name`` values become
the ``{{ placeholder }}`` tokens inside the matching template in
``doc_templates/``.

To add a new matter type:
    1. Add an entry to ``MATTER_TYPES`` below with its fields.
    2. Create a matching ``doc_templates/<template>.docx`` containing
       ``{{ field_name }}`` placeholders (see README).
That's it -- the form, validation, and generation are all data-driven.
"""

# Reusable field groups -------------------------------------------------------

# Field type is one of: "text", "textarea", "date", "time".
# "section" groups fields visually in the form.

_COURT_FIELDS = [
    {"name": "court_county", "label": "County", "type": "text",
     "required": True, "section": "Court"},
    {"name": "court_state", "label": "State", "type": "text",
     "required": True, "section": "Court"},
    {"name": "case_number", "label": "Case Number", "type": "text",
     "required": False, "section": "Court",
     "help": "Leave blank if not yet assigned."},
]

_ATTORNEY_FIELDS = [
    {"name": "attorney_name", "label": "Attorney Name", "type": "text",
     "required": True, "section": "Attorney of Record"},
    {"name": "attorney_bar_number", "label": "Bar Number", "type": "text",
     "required": False, "section": "Attorney of Record"},
    {"name": "attorney_firm", "label": "Firm Name", "type": "text",
     "required": False, "section": "Attorney of Record"},
    {"name": "attorney_address", "label": "Firm Address", "type": "textarea",
     "required": False, "section": "Attorney of Record"},
    {"name": "attorney_phone", "label": "Phone", "type": "text",
     "required": False, "section": "Attorney of Record"},
    {"name": "attorney_email", "label": "Email", "type": "text",
     "required": False, "section": "Attorney of Record"},
]


MATTER_TYPES = {
    "divorce_petition": {
        "label": "Divorce Petition",
        "description": "Petition for dissolution of marriage.",
        "template": "divorce_petition.docx",
        # Field used to name/identify the matter in the history list.
        "client_field": "petitioner_name",
        "fields": _COURT_FIELDS + [
            {"name": "petitioner_name", "label": "Petitioner Full Name",
             "type": "text", "required": True, "section": "Parties"},
            {"name": "petitioner_address", "label": "Petitioner Address",
             "type": "textarea", "required": False, "section": "Parties"},
            {"name": "respondent_name", "label": "Respondent Full Name",
             "type": "text", "required": True, "section": "Parties"},
            {"name": "respondent_address", "label": "Respondent Address",
             "type": "textarea", "required": False, "section": "Parties"},
            {"name": "marriage_date", "label": "Date of Marriage",
             "type": "date", "required": False, "section": "Marriage"},
            {"name": "marriage_place", "label": "Place of Marriage",
             "type": "text", "required": False, "section": "Marriage"},
            {"name": "separation_date", "label": "Date of Separation",
             "type": "date", "required": False, "section": "Marriage"},
            {"name": "grounds", "label": "Grounds for Dissolution",
             "type": "textarea", "required": False, "section": "Allegations",
             "help": "e.g. irreconcilable differences."},
            {"name": "minor_children", "label": "Minor Children",
             "type": "textarea", "required": False, "section": "Allegations",
             "help": "List names and dates of birth, or 'None'."},
            {"name": "relief_requested", "label": "Relief Requested",
             "type": "textarea", "required": False, "section": "Allegations"},
        ] + _ATTORNEY_FIELDS + [
            {"name": "filing_date", "label": "Filing Date", "type": "date",
             "required": False, "section": "Signature"},
        ],
    },

    "parenting_plan": {
        "label": "Parenting Plan",
        "description": "Custody and parenting time agreement.",
        "template": "parenting_plan.docx",
        "client_field": "parent_one_name",
        "fields": _COURT_FIELDS + [
            {"name": "parent_one_name", "label": "Parent One Full Name",
             "type": "text", "required": True, "section": "Parents"},
            {"name": "parent_two_name", "label": "Parent Two Full Name",
             "type": "text", "required": True, "section": "Parents"},
            {"name": "children", "label": "Children",
             "type": "textarea", "required": True, "section": "Children",
             "help": "List each child's name and date of birth."},
            {"name": "residential_schedule", "label": "Residential Schedule",
             "type": "textarea", "required": False, "section": "Schedule",
             "help": "Day-to-day living arrangements."},
            {"name": "holiday_schedule", "label": "Holiday Schedule",
             "type": "textarea", "required": False, "section": "Schedule"},
            {"name": "decision_making", "label": "Decision Making",
             "type": "textarea", "required": False, "section": "Authority",
             "help": "Education, health, religion, etc."},
            {"name": "transportation", "label": "Transportation & Exchange",
             "type": "textarea", "required": False, "section": "Authority"},
        ] + _ATTORNEY_FIELDS + [
            {"name": "agreement_date", "label": "Agreement Date",
             "type": "date", "required": False, "section": "Signature"},
        ],
    },

    "notice_of_hearing": {
        "label": "Notice of Hearing",
        "description": "Notice setting a matter for hearing.",
        "template": "notice_of_hearing.docx",
        "client_field": "petitioner_name",
        "fields": _COURT_FIELDS + [
            {"name": "petitioner_name", "label": "Petitioner Full Name",
             "type": "text", "required": True, "section": "Parties"},
            {"name": "respondent_name", "label": "Respondent Full Name",
             "type": "text", "required": True, "section": "Parties"},
            {"name": "hearing_matter", "label": "Matter to be Heard",
             "type": "text", "required": True, "section": "Hearing",
             "help": "e.g. 'Motion for Temporary Support'."},
            {"name": "hearing_date", "label": "Hearing Date", "type": "date",
             "required": True, "section": "Hearing"},
            {"name": "hearing_time", "label": "Hearing Time", "type": "time",
             "required": True, "section": "Hearing"},
            {"name": "hearing_location", "label": "Location / Courtroom",
             "type": "textarea", "required": True, "section": "Hearing"},
            {"name": "judge_name", "label": "Judge", "type": "text",
             "required": False, "section": "Hearing"},
        ] + _ATTORNEY_FIELDS + [
            {"name": "notice_date", "label": "Notice Date", "type": "date",
             "required": False, "section": "Signature"},
        ],
    },
}


def get_matter(matter_key):
    """Return the matter definition or None if unknown."""
    return MATTER_TYPES.get(matter_key)


def matter_list():
    """Return [(key, definition), ...] for display."""
    return list(MATTER_TYPES.items())
