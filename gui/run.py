from app import app, appbuilder, db
from sqlalchemy import Table, MetaData
from flask_appbuilder import Model
from flask import jsonify
from sqlalchemy.exc import SQLAlchemyError

app.run(host="0.0.0.0", port=8080, debug=True)
