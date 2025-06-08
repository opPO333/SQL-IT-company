from flask_appbuilder import Model
from sqlalchemy import Table, MetaData, Column, Integer, String, Date, and_, null
from sqlalchemy.orm import relationship, foreign

from app import db
from sqlalchemy.sql.schema import Column, ForeignKey
from sqlalchemy.sql.sqltypes import Integer, String, Numeric

metadata = MetaData(bind=db.engine)

all_employees_table = Table(
    'employees', metadata,
    autoload=True, autoload_with=db.engine
)

employee_table = Table(
    'employees_view', metadata,
    Column('id', Integer, primary_key=True),
    Column('first_name', String),
    Column('last_name', String),
    Column('second_name', String),
    Column('gender', String(1)),
    Column('phone', String),
    Column('email', String),
    Column('pesel', String),
    Column('passport', String),
    Column('department_name', String),
    Column('department_start_date', Date),
    Column('team_id', Integer),
    Column('position_name', String),
    Column('salary_per_hour', String),
    Column('correspondence_address_id', Integer),
    Column('birth_date', Date),
)
departments_table = Table('departments_view', metadata,
                          Column('name', String, primary_key=True),
                          Column('start_date', Date),
                          Column('head_id', Integer),
                          )

teams_table = Table('teams_view', metadata,
                    Column('id', String, primary_key=True),
                    Column('project_title', String),
                    )
employees_departments_table = Table('employee_departments_history_view',
                                    metadata,
                                    Column('employee_id', Integer, primary_key=True),
                                    Column('name', String, primary_key=True),
                                    Column('department_name', String, primary_key=True),
                                    Column('start_date', Date, primary_key=True),
                                    Column('end_date', Date))

employee_name_history_table = Table('employee_name_history',
                                    metadata, autoload=True, autoload_with=db.engine)

head_departments_history_table = Table('head_departments_history', metadata,
                                      autoload=True, autoload_with=db.engine )
positions_table = Table('positions', metadata, autoload=True, autoload_with=db.engine)

class AllEmployees(db.Model):
    __table__ = all_employees_table
    def __repr__(self):
        return f"{self.first_name} {self.last_name}"

class Employee(db.Model):
    __table__ = employee_table
    def __repr__(self):
        return f"{self.first_name} {self.last_name}"

class Position(db.Model):
    __table__ = positions_table
    employees = relationship(
        Employee,
        viewonly=True,
        primaryjoin=and_(
            positions_table.c.position == foreign(employee_table.c.position_name),
        ),
        backref='position'
    )
    def __repr__(self):
        return f"{self.position}"


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
    head = relationship(
        Employee,
        viewonly=True,
        primaryjoin=and_(
            departments_table.c.head_id == foreign(employee_table.c.id),
        ),
        backref='head'
    )
    def __repr__(self):
        return f"{self.name}"

class EmployeeDepartmentHistory(db.Model):
    __table__ = employees_departments_table

    employee = relationship(
        AllEmployees,
        viewonly=True,
        primaryjoin=and_(
            employees_departments_table.c.employee_id == foreign(all_employees_table.c.id),
        ),
        backref='edh_employee_history'
    )
    department = relationship(
        Department,
        viewonly=True,
        primaryjoin=and_(
            employees_departments_table.c.department_name == foreign(departments_table.c.name),
        ),
        backref='edh_department_history'
    )

class EmployeeNameHistory(db.Model):
    __table__ = employee_name_history_table
    employee = relationship(
        AllEmployees,
        viewonly=True,
        primaryjoin=and_(
            employee_name_history_table.c.employee_id == foreign(all_employees_table.c.id),
        ),
        backref='employee_name_history'
    )

class HeadDepartmentsHistory(db.Model):
    __table__ = head_departments_history_table
    head = relationship(
        AllEmployees,
        viewonly=True,
        primaryjoin=and_(
            head_departments_history_table.c.head_id == foreign(all_employees_table.c.id),
        ),
        backref='head_history'
    )

    department = relationship(
        Department,
        viewonly=True,
        primaryjoin=and_(
            head_departments_history_table.c.department_name == foreign(departments_table.c.name),
        ),
        backref='department_history'
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
    def __repr__(self):
        return f"{self.id} {self.project_title}"
