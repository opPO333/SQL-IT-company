from app import app, appbuilder, db
from sqlalchemy import Table, MetaData
from flask_appbuilder import Model



app.run(host="0.0.0.0", port=8080, debug=True)
