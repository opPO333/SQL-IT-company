from flask_appbuilder import Model
from sqlalchemy import MetaData, Table
from sqlalchemy.orm import relationship
from app import db

metadata = MetaData(bind=db.engine)
employee_table = Table('employees', metadata, autoload=True)
departments_table = Table('departments', metadata, autoload=True)

class employees(db.Model):
    __table__ = employee_table

class departments(db.Model):
    __table__ = departments_table 