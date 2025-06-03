from flask_appbuilder import Model
from sqlalchemy import Table, MetaData, Column, Integer, String, Date, and_
from sqlalchemy.orm import relationship, foreign

from app import db
from sqlalchemy.sql.schema import Column, ForeignKey
from sqlalchemy.sql.sqltypes import Integer, String

metadata = MetaData(bind=db.engine)
employee_table = Table(
    'employees_view', metadata,
    Column('id', Integer, primary_key=True),
    Column('first_name', String),
    Column('last_name', String),
    Column('pesel', String),
    Column('department_name', String),
    Column('department_start_date', Date),
    Column('team_id', Integer),
)
departments_table = Table('departments_view', metadata,
                          Column('name', String, primary_key=True),
                          Column('start_date', Date),
                          Column('head_name', String),
                          )

teams_table = Table('teams_view', metadata,
                    Column('id', String, primary_key=True),
                    Column('project_title', String),
                    )


class Employee(db.Model):
    __table__ = employee_table

class Department(db.Model):
    __table__ = departments_table

    employees = relationship(
        Employee,
        viewonly=True,
        primaryjoin=and_(
            departments_table.c.name == foreign(employee_table.c.department_name),
        ),
        backref='department'
    )

class Team(db.Model):
    __table__ = teams_table

    employees = relationship(
        Employee,
        viewonly=True,
        primaryjoin=and_(
            teams_table.c.id == foreign(employee_table.c.team_id),
        ),
        backref = 'team'
    )
