"""Law office document generator -- local Flask web app.

Run with:  python app.py
Then open: http://127.0.0.1:5000
"""

from flask import (
    Flask, render_template, request, redirect, url_for,
    flash, send_from_directory, abort,
)

import config
import database
from document_generator import generate_document, build_output_filename
from matters import get_matter, matter_list

app = Flask(__name__)
app.config["SECRET_KEY"] = config.SECRET_KEY


@app.route("/")
def index():
    return render_template("index.html", matters=matter_list())


@app.route("/new/<matter_key>", methods=["GET", "POST"])
def new_document(matter_key):
    matter = get_matter(matter_key)
    if matter is None:
        abort(404)

    if request.method == "POST":
        data = {f["name"]: request.form.get(f["name"], "").strip()
                for f in matter["fields"]}

        # Validate required fields.
        missing = [f["label"] for f in matter["fields"]
                   if f.get("required") and not data.get(f["name"])]
        if missing:
            flash("Please fill in required fields: " + ", ".join(missing),
                  "error")
            return render_template("form.html", matter=matter,
                                   matter_key=matter_key, values=data)

        client_name = data.get(matter.get("client_field", ""), "") or "client"
        output_filename = build_output_filename(matter_key, client_name)
        template_path = config.TEMPLATE_DIR / matter["template"]
        output_path = config.OUTPUT_DIR / output_filename

        try:
            generate_document(template_path, data, output_path)
        except FileNotFoundError:
            flash(f"Template missing: {matter['template']}. "
                  "Run create_templates.py to generate the starter templates.",
                  "error")
            return render_template("form.html", matter=matter,
                                   matter_key=matter_key, values=data)

        database.save_submission(matter_key, client_name, data, output_filename)
        flash("Document generated successfully.", "success")
        return redirect(url_for("download", filename=output_filename))

    return render_template("form.html", matter=matter,
                           matter_key=matter_key, values={})


@app.route("/history")
def history():
    submissions = database.list_submissions()
    labels = {key: m["label"] for key, m in matter_list()}
    return render_template("history.html", submissions=submissions,
                           labels=labels)


@app.route("/download/<path:filename>")
def download(filename):
    return send_from_directory(config.OUTPUT_DIR, filename, as_attachment=True)


@app.errorhandler(404)
def not_found(_error):
    return render_template("error.html", message="Page not found."), 404


def main():
    database.init_db()
    config.OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    app.run(host=config.HOST, port=config.PORT, debug=True)


if __name__ == "__main__":
    main()
