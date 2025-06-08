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
    Column('first_name', String, nullable=False),
    Column('last_name', String, nullable=False),
    Column('second_name', String),
    Column('gender', String(1), nullable=False),
    Column('phone', String),
    Column('email', String),
    Column('pesel', String),
    Column('passport', String),
    Column('department_name', String),
    Column('department_start_date', Date),
    Column('team_id', Integer),
    Column('position_name', String, nullable=False),
    Column('salary', Integer),
    Column('birth_date', Date, nullable=False),
    Column('correspondence_street', String, nullable=False),
    Column('correspondence_house', String, nullable=False),
    Column('correspondence_city_id', Integer, nullable=False),
    Column('correspondence_postal_code', String, nullable=False),
    Column('street', String),
    Column('house', String),
    Column('city_id', Integer),
    Column('postal_code', String),
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

salary_history_table = Table('employee_salary', metadata, autoload=True, autoload_with=db.engine)

cities_table = Table('cities', metadata, autoload=True, autoload_with=db.engine)
regions_table = Table('regions', metadata, autoload=True, autoload_with=db.engine)
countries_table = Table('countries', metadata, autoload=True, autoload_with=db.engine)

class AllEmployees(db.Model):
    __table__ = all_employees_table
    def __repr__(self):
        return f"{self.first_name} {self.last_name}"

class Employee(db.Model):
    __table__ = employee_table

    def __repr__(self):
        return f"{self.first_name} {self.last_name}"

class Cities(db.Model):
    __table__ = cities_table
    correspondence_employee = relationship(
        Employee,
        primaryjoin=and_(
            cities_table.c.id == foreign(employee_table.c.correspondence_city_id),
        ),
        backref='correspondence_city'
    )
    employee = relationship(
        Employee,
        primaryjoin=and_(
            cities_table.c.id == foreign(employee_table.c.city_id),
        ),
        backref='city'
    )

    def __repr__(self):
        return f"{self.region}, {self.name}"

class Regions(db.Model):
    __table__ = regions_table
    city = relationship(
        Cities,
        primaryjoin=and_(
            regions_table.c.id == foreign(cities_table.c.region_id),
        ),
        backref='region'
    )
    def __repr__(self):
        return f"{self.country}, {self.name}"
class Countries(db.Model):
    __table__ = countries_table
    region = relationship(
        Regions,
        primaryjoin=and_(
            countries_table.c.name == foreign(regions_table.c.country_name),
        ),
        backref='country'
    )
    def __repr__(self):
        return f"{self.name}"

class Position(db.Model):
    __table__ = positions_table
    employees = relationship(
        Employee,
        primaryjoin=and_(
            positions_table.c.position == foreign(employee_table.c.position_name),
        ),
        backref='position'
    )
    def __repr__(self):
        return f"{self.position}"

class SalaryHistory(db.Model):
    __table__ = salary_history_table
    employee = relationship(
        AllEmployees,
        primaryjoin=and_(
            salary_history_table.c.employee_id == foreign(all_employees_table.c.id),
        ),
        backref='salary_history'
    )


class Department(db.Model):
    __table__ = departments_table

    employees = relationship(
        Employee,
        primaryjoin=and_(
            departments_table.c.name == foreign(employee_table.c.department_name),
        ),
        backref='department'
    )
    head = relationship(
        Employee,
        primaryjoin=and_(
            departments_table.c.head_id == foreign(employee_table.c.id),
        )
    )
    def __repr__(self):
        return f"{self.name}"

class EmployeeDepartmentHistory(db.Model):
    __table__ = employees_departments_table

    employee = relationship(
        AllEmployees,
        primaryjoin=and_(
            employees_departments_table.c.employee_id == foreign(all_employees_table.c.id),
        ),
        backref='edh_employee_history'
    )
    department = relationship(
        Department,
        primaryjoin=and_(
            employees_departments_table.c.department_name == foreign(departments_table.c.name),
        ),
        backref='edh_department_history'
    )

class EmployeeNameHistory(db.Model):
    __table__ = employee_name_history_table
    employee = relationship(
        AllEmployees,
        primaryjoin=and_(
            employee_name_history_table.c.employee_id == foreign(all_employees_table.c.id),
        ),
        backref='employee_name_history'
    )

class HeadDepartmentsHistory(db.Model):
    __table__ = head_departments_history_table
    head = relationship(
        AllEmployees,
        primaryjoin=and_(
            head_departments_history_table.c.head_id == foreign(all_employees_table.c.id),
        ),
        backref='head_history'
    )

    department = relationship(
        Department,
        primaryjoin=and_(
            head_departments_history_table.c.department_name == foreign(departments_table.c.name),
        ),
        backref='department_history'
    )


class Team(db.Model):
    __table__ = teams_table

    employees = relationship(
        Employee,
        primaryjoin=and_(
            teams_table.c.id == foreign(employee_table.c.team_id),
        ),
        backref = 'team'
    )
    def __repr__(self):
        return f"{self.id} {self.project_title}"
