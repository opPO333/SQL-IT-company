import logging

from flask import Flask
from flask_appbuilder import AppBuilder, SQLA

logging.basicConfig(format="%(asctime)s:%(levelname)s:%(name)s:%(message)s")
logging.getLogger().setLevel(logging.DEBUG)

# Add this line to suppress noisy socket errors from the dev server:
logging.getLogger("werkzeug.serving").setLevel(logging.INFO)

app = Flask(__name__)
app.config.from_object("config")
db = SQLA(app)
appbuilder = AppBuilder(app, db.session)

from . import views