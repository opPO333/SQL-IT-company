from flask import render_template
from flask_appbuilder.models.sqla.interface import SQLAInterface
from flask_appbuilder import ModelView, ModelRestApi
from .models import *
from flask import g, flash, redirect, url_for, abort
from flask_migrate import Migrate
import json
import datetime


from . import appbuilder, db

"""
    Create your Model based REST API::

    class MyModelApi(ModelRestApi):
        datamodel = SQLAInterface(MyModel)

    appbuilder.add_api(MyModelApi)


    Create your Views::


    class MyModelView(ModelView):
        datamodel = SQLAInterface(MyModel)


    Next, register your Views::


    appbuilder.add_view(
        MyModelView,
        "My View",
        icon="fa-folder-open-o",
        category="My Category",
        category_icon='fa-envelope'
    )
"""

"""
    Application wide 404 error handler
"""


@appbuilder.app.errorhandler(404)
def page_not_found(e):
    return (
        render_template(
            "404.html", base_template=appbuilder.base_template, appbuilder=appbuilder
        ),
        404,
    )


from flask_appbuilder.fieldwidgets import BS3TextFieldWidget
from wtforms import StringField
from wtforms.validators import DataRequired
class EmployeeView(ModelView):
    datamodel = SQLAInterface(Employee)
    list_columns = ['first_name', 'last_name']

    # Updated show columns to display nested attributes
    show_columns = [
        'first_name', 'last_name', 'second_name', 'gender', 'phone', 'email',
        'pesel', 'passport', 'department', 'position', 'salary', 'team',
        'correspondence_city',
        'correspondence_street', 'correspondence_house',
        'correspondence_postal_code',
        'city',
        'street', 'house', 'postal_code', 'birth_date'
    ]

    add_columns = edit_columns = show_columns

    # Handle empty valuesd
    def _empty_to_none(self, item):
        for col in self.edit_columns:
            if getattr(item, col) == '':
                setattr(item, col, None)

    def pre_add(self, item):
        if not(g.user.is_admin() or g.user.id == item.department.head_id):
            abort(403)
        self._empty_to_none(item)

    def pre_update(self, item):
        if not(g.user.is_admin() or g.user.employee.id == item.id  or g.user.id == item.department.head_id):
            abort(403)
        self._empty_to_none(item)

class PositionView(ModelView):
    datamodel = SQLAInterface(Position)
    related_views = [EmployeeView]
    list_columns = ['position'];
    show_template = "appbuilder/general/model/show_cascade.html"


class DepartmentView(ModelView):
    datamodel = SQLAInterface(Department)
    list_columns = ['name']
    show_columns = ['name', 'head', 'start_date']
    add_columns = ['name', 'head', 'start_date']
    base_order = ('name', 'asc')
    related_views = [EmployeeView]
    show_template = "appbuilder/general/model/show_cascade.html"

class EmployeeNameHistory(ModelView):
    datamodel = SQLAInterface(EmployeeNameHistory)
    base_permissions = ['can_list']
    list_columns = ['employee', 'first_name', 'last_name', 'second_name', 'start_ts', 'end_ts']

class TeamView(ModelView):
    datamodel = SQLAInterface(Team)
    list_columns = ['id', 'project_title']
    show_columns = [
        'id', 'project_title'
    ]
    related_views = [EmployeeView]
    show_template = "appbuilder/general/model/show_cascade.html"

class EmployeeDepartmentHistoryView(ModelView):
    datamodel = SQLAInterface(EmployeeDepartmentHistory)
    base_permissions = ['can_list']
    list_columns = ['employee', 'department_name', 'start_date', 'end_date']

class HeadDepartmentHistoryView(ModelView):
    datamodel = SQLAInterface(HeadDepartmentsHistory)
    base_permissions = ['can_list']
    list_columns = ['department', 'head', 'start_date', 'end_date']

class SalaryHistoryView(ModelView):
    datamodel = SQLAInterface(SalaryHistory)
    base_permissions = ['can_list']
    list_columns = ['employee', 'start_date', 'end_date', 'salary']

appbuilder.add_view(
    EmployeeView,
    "Employees"
    , icon="fa-users",
    category="Company",
    category_icon='fa-building')
appbuilder.add_view(
    DepartmentView,
    "Departments"
    , icon="fa-building",
    category="Company",
    category_icon='fa-building')
appbuilder.add_view(
    TeamView,
    "Teams"
    , icon="fa-building",
    category="Company",
    category_icon='fa-building'
)
appbuilder.add_view(
    EmployeeDepartmentHistoryView,
    "Employee Department History"
    , icon="fa-building",
    category="History",
    category_icon='fa-address-book'
)

appbuilder.add_view(
    PositionView,
    "Positions"
    , icon="fa-users",
    category="Company",)
appbuilder.add_view(EmployeeNameHistory,
                    "Employee Name History",
                    icon="fa-users",
                    category="History",
                    category_icon='fa-address-book')

appbuilder.add_view(HeadDepartmentHistoryView,
                    "Head Department History",
                    icon="fa-building",
                    category="History" )

appbuilder.add_view(SalaryHistoryView,
                    "Salary History",
                    icon="fa-money",
                    category="History" )


db.create_all()
